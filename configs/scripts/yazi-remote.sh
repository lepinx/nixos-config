select_with_fzf() {
  fzf --height=70% --border --reverse "$@" || true
}

mounted_remotes() {
  local rclone_root="$HOME/mnt/rclone"
  local gvfs_root

  gvfs_root="/run/user/$(id -u)/gvfs"

  if [ -d "$rclone_root" ]; then
    while IFS= read -r -d '' path; do
      printf 'rclone\t%s\t%s\n' "$(basename "$path")" "$path"
    done < <(find "$rclone_root" -mindepth 1 -maxdepth 1 -type d -print0)
  fi

  if [ -d "$gvfs_root" ]; then
    while IFS= read -r -d '' path; do
      printf 'gvfs\t%s\t%s\n' "$(basename "$path")" "$path"
    done < <(find "$gvfs_root" -mindepth 1 -maxdepth 1 -type d -print0)
  fi
}

choose_mounted_remote() {
  local selection

  selection=$(mounted_remotes | select_with_fzf --prompt='Remoto montado > ' --delimiter='\t' --with-nth=1,2,3)
  [ -n "$selection" ] || return 1

  printf '%s\n' "$selection"
}

open_mounted_remote() {
  local selection path

  selection=$(choose_mounted_remote) || return 1
  path=$(printf '%s\n' "$selection" | awk -F '\t' '{ print $3 }')
  [ -n "$path" ] || return 1

  printf '%s\n' "$path"
}

mount_rclone_remote() {
  local remote name mountpoint

  remote=$(rclone listremotes | select_with_fzf --prompt='rclone remote > ')
  if [ -z "$remote" ]; then
    printf 'No hay remotes de rclone. Usa: rclone config\n' >&2
    return 1
  fi

  name=${remote%:}
  name=${name//[^A-Za-z0-9._-]/_}
  mountpoint="$HOME/mnt/rclone/$name"

  mkdir -p "$mountpoint"

  if ! mountpoint -q "$mountpoint"; then
    rclone mount "$remote" "$mountpoint" --daemon --vfs-cache-mode writes
    sleep 1
  fi

  printf '%s\n' "$mountpoint"
}

mount_gvfs_remote() {
  local url

  printf 'URL remoto (ej: sftp://user@host/, davs://host/path): ' >&2
  read -r url
  [ -n "$url" ] || return 1

  gio mount "$url"
  sleep 1
  open_mounted_remote
}

unmount_remote() {
  local selection kind path

  selection=$(choose_mounted_remote) || return 1
  kind=$(printf '%s\n' "$selection" | awk -F '\t' '{ print $1 }')
  path=$(printf '%s\n' "$selection" | awk -F '\t' '{ print $3 }')
  [ -n "$path" ] || return 1

  case "$kind" in
    rclone)
      fusermount3 -u "$path" || umount "$path"
      ;;
    gvfs)
      gio mount -u "$path"
      ;;
  esac
}

select_remote_path() {
  local action path

  while true; do
    action=$(printf '%s\n' \
      'Abrir remoto montado' \
      'Montar rclone' \
      'Montar GVFS URL' \
      'Desmontar remoto' \
      'Configurar rclone' \
      'Salir' \
      | select_with_fzf --prompt='Remotos > ')

    case "$action" in
      'Abrir remoto montado')
        path=$(open_mounted_remote) && {
          printf '%s\n' "$path"
          return 0
        }
        ;;
      'Montar rclone')
        path=$(mount_rclone_remote) && {
          printf '%s\n' "$path"
          return 0
        }
        ;;
      'Montar GVFS URL')
        path=$(mount_gvfs_remote) && {
          printf '%s\n' "$path"
          return 0
        }
        ;;
      'Desmontar remoto')
        unmount_remote || true
        ;;
      'Configurar rclone')
        rclone config || true
        ;;
      ''|'Salir')
        return 1
        ;;
    esac
  done
}

case "${1:-menu}" in
  path)
    select_remote_path
    ;;
  mount-rclone)
    mount_rclone_remote
    ;;
  mount-gvfs)
    mount_gvfs_remote
    ;;
  unmount)
    unmount_remote
    ;;
  config)
    rclone config
    ;;
  menu|open)
    path=$(select_remote_path) || exit 0
    [ -n "$path" ] || exit 0
    exec yazi "$path"
    ;;
  *)
    printf 'Uso: yazi-remote [path|open|mount-rclone|mount-gvfs|unmount|config]\n' >&2
    exit 2
    ;;
esac
