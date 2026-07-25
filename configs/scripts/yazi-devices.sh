select_with_fzf() {
  fzf --height=70% --border --reverse "$@" || true
}

devices() {
  lsblk -Jp -o NAME,PKNAME,TYPE,SIZE,LABEL,MODEL,TRAN,RM,MOUNTPOINTS \
    | jq -r '
      def flat:
        . as $dev | [$dev] + (($dev.children // []) | map(flat) | add // []);

      .blockdevices[] as $root
      | ($root | flat)[] as $dev
      | select($dev.type == "part" or ($dev.type == "disk" and (($dev.children // []) | length == 0)))
      | select(
          ($root.rm == true)
          or ($root.tran == "usb")
          or ((($dev.mountpoints // []) | map(select(. != null and startswith("/run/media/"))) | length) > 0)
        )
      | [
          $dev.name,
          ($dev.pkname // $root.name),
          ($dev.label // $dev.model // $root.model // "sin etiqueta"),
          ($dev.size // ""),
          (($dev.mountpoints // []) | map(select(. != null and . != "")) | join(","))
        ]
      | @tsv'
}

choose_device() {
  local mode="$1"
  local prompt="$2"
  local rows

  case "$mode" in
    mounted)
      rows=$(devices | awk -F '\t' '$5 != ""')
      ;;
    unmounted)
      rows=$(devices | awk -F '\t' '$5 == ""')
      ;;
    *)
      rows=$(devices)
      ;;
  esac

  [ -n "$rows" ] || return 1
  printf '%s\n' "$rows" | select_with_fzf --prompt="$prompt" --delimiter='\t' --with-nth=3,4,5,1
}

open_mounted_device() {
  local selection mountpoints path

  selection=$(choose_device mounted 'Disco montado > ') || return 1
  mountpoints=$(printf '%s\n' "$selection" | awk -F '\t' '{ print $5 }')
  path=${mountpoints%%,*}
  [ -n "$path" ] || return 1

  printf '%s\n' "$path"
}

mount_device() {
  local selection device output path

  selection=$(choose_device unmounted 'Montar disco > ') || return 1
  device=$(printf '%s\n' "$selection" | awk -F '\t' '{ print $1 }')
  [ -n "$device" ] || return 1

  output=$(udisksctl mount -b "$device")
  path=$(printf '%s\n' "$output" | sed -n 's/.* at \(.*\)\.$/\1/p')

  if [ -n "$path" ]; then
    printf '%s\n' "$path"
  else
    open_mounted_device
  fi
}

unmount_device() {
  local selection device parent answer

  selection=$(choose_device mounted 'Desmontar disco > ') || return 1
  device=$(printf '%s\n' "$selection" | awk -F '\t' '{ print $1 }')
  parent=$(printf '%s\n' "$selection" | awk -F '\t' '{ print $2 }')
  [ -n "$device" ] || return 1

  udisksctl unmount -b "$device"

  answer=$(printf '%s\n' 'No' 'Si, apagar/ejectar' | select_with_fzf --prompt='Apagar dispositivo? ')
  if [ "$answer" = 'Si, apagar/ejectar' ]; then
    udisksctl power-off -b "${parent:-$device}" || udisksctl power-off -b "$device" || true
  fi
}

select_device_path() {
  local action path

  while true; do
    action=$(printf '%s\n' \
      'Abrir disco montado' \
      'Montar disco' \
      'Desmontar/ejectar disco' \
      'Salir' \
      | select_with_fzf --prompt='Discos > ')

    case "$action" in
      'Abrir disco montado')
        path=$(open_mounted_device) && {
          printf '%s\n' "$path"
          return 0
        }
        ;;
      'Montar disco')
        path=$(mount_device) && {
          printf '%s\n' "$path"
          return 0
        }
        ;;
      'Desmontar/ejectar disco')
        unmount_device || true
        ;;
      ''|'Salir')
        return 1
        ;;
    esac
  done
}

case "${1:-menu}" in
  path)
    select_device_path
    ;;
  mount)
    mount_device
    ;;
  unmount|eject)
    unmount_device
    ;;
  menu|open)
    path=$(select_device_path) || exit 0
    [ -n "$path" ] || exit 0
    exec yazi "$path"
    ;;
  *)
    printf 'Uso: yazi-devices [path|open|mount|unmount|eject]\n' >&2
    exit 2
    ;;
esac
