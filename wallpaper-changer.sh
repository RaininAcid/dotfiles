#!/bin/bash

# Проверяем, установлен ли dialog
if ! command -v dialog &> /dev/null; then
    echo "Устанавливаю dialog..."
    sudo pacman -S dialog --noconfirm
fi

# Папка с обоями (замени на свою, если нужно)
WALLPAPER_DIR="$HOME/.config/wallpapers/"

# Проверяем, существует ли папка
if [ ! -d "$WALLPAPER_DIR" ]; then
    dialog --title "Ошибка" --msgbox "Папка '$WALLPAPER_DIR' не существует." 8 50
    exit 1
fi

# Получаем список обоев
WALLPAPERS=($(ls "$WALLPAPER_DIR" | grep -E '\.(jpg|png|jpeg|webp)$'))

# Если обоев нет, выводим ошибку
if [ ${#WALLPAPERS[@]} -eq 0 ]; then
    dialog --title "Ошибка" --msgbox "Нет обоев в '$WALLPAPER_DIR'" 8 50
    exit 1
fi

# Выбор обоев через dialog
CHOSEN_WALLPAPER=$(dialog --title "Выберите обои" --menu "Выберите обои для HDMI-A-1:" 15 50 6 \
    $(for i in "${!WALLPAPERS[@]}"; do echo "$i" "${WALLPAPERS[$i]}"; done) \
    3>&1 1>&2 2>&3)

# Если выбор отменен — выходим
if [ -z "$CHOSEN_WALLPAPER" ]; then
    clear
    exit 0
fi

# Полный путь к выбранному изображению
SELECTED_PATH="$WALLPAPER_DIR/${WALLPAPERS[$CHOSEN_WALLPAPER]}"

# Проверяем, запущен ли swww-daemon
if ! pgrep -x "swww-daemon" > /dev/null; then
    swww-daemon &
    sleep 1  # Даем время демону запуститься
fi

# Устанавливаем обои на HDMI-A-1
swww img "$SELECTED_PATH" --outputs DVI-I-1

# Генерируем цветовую схему с pywal
wal -i "$SELECTED_PATH"

# Обновляем окружение с новыми цветами
#pkill -USR1 waybar         # Перезапуск Waybar
hyprctl reload             # Перезагрузка Hyprland
killall -SIGUSR1 kitty     # Перезагрузка kitty (если используется)
killall -USR1 rofi         # Перезагрузка Rofi (если используется)

clear
echo "✅ Обои и цветовая схема обновлены для DVI-I-1!"
