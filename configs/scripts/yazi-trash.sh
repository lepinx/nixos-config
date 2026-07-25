select_with_fzf() {
  fzf --height=70% --border --reverse "$@" || true
}

trash_dir() {
  printf '%s/Trash/files\n' "${XDG_DATA_HOME:-$HOME/.local/share}"
}

open_trash() {
  local path

  path=$(trash_dir)
  mkdir -p "$path"
  printf '%s\n' "$path"
}

restore_trash() {
  trash-list || true
  printf '\nSelecciona el item a restaurar con trash-restore.\n' >&2
  trash-restore || true
  open_trash
}

empty_trash() {
  local answer

  answer=$(printf '%s\n' 'No' 'Si, vaciar papelera' | select_with_fzf --prompt='Confirmar > ')
  if [ "$answer" = 'Si, vaciar papelera' ]; then
    trash-empty
  fi

  open_trash
}

list_trash() {
  trash-list | less -R || true
  open_trash
}

select_trash_path() {
  local action path

  while true; do
    action=$(printf '%s\n' \
      'Abrir papelera' \
      'Restaurar item' \
      'Vaciar papelera' \
      'Listar papelera' \
      'Salir' \
      | select_with_fzf --prompt='Papelera > ')

    case "$action" in
      'Abrir papelera')
        path=$(open_trash) && {
          printf '%s\n' "$path"
          return 0
        }
        ;;
      'Restaurar item')
        path=$(restore_trash) && {
          printf '%s\n' "$path"
          return 0
        }
        ;;
      'Vaciar papelera')
        path=$(empty_trash) && {
          printf '%s\n' "$path"
          return 0
        }
        ;;
      'Listar papelera')
        path=$(list_trash) && {
          printf '%s\n' "$path"
          return 0
        }
        ;;
      ''|'Salir')
        return 1
        ;;
    esac
  done
}

case "${1:-menu}" in
  path)
    select_trash_path
    ;;
  restore)
    restore_trash
    ;;
  empty)
    empty_trash
    ;;
  list)
    list_trash
    ;;
  menu|open)
    path=$(select_trash_path) || exit 0
    [ -n "$path" ] || exit 0
    exec yazi "$path"
    ;;
  *)
    printf 'Uso: yazi-trash [path|open|restore|empty|list]\n' >&2
    exit 2
    ;;
esac
