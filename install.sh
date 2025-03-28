#!/bin/bash

# بررسی وضعیت نصب تونل
if grep -q "tunnel-PD" /etc/rc.local 2>/dev/null; then
    STATUS="\e[32m✅ Installed\e[0m"  # تیک سبز برای نصب شده
else
    STATUS="\e[31m❌ Not Installed\e[0m"  # ضربدر قرمز برای نصب نشده
fi

while true; do
    clear
    echo -e "\e[1m\e[38;5;39m==============================\e[0m"  # آبی کم‌رنگ و بولد
    echo -e "\e[1m\e[38;5;39m      PDIPV6TUN Installer     \e[0m"  # آبی کم‌رنگ و بولد
    echo -e "\e[1m\e[38;5;39m==============================\e[0m"  # آبی کم‌رنگ و بولد
    echo -e "\e[1mTunnel Status: $STATUS\e[0m"  # وضعیت نصب تونل
    echo -e "\e[1m==============================\e[0m"  # بولد کردن خط جداکننده
    echo -e "\e[1m| 1) Install Tunnel          |\e[0m"
    echo -e "\e[1m| 2) Show Assigned Local IPv6|\e[0m"
    echo -e "\e[1m| 3) Remove Tunnel           |\e[0m"
    echo -e "\e[1m| 4) Exit                    |\e[0m"
    echo -e "\e[1m==============================\e[0m"  # بولد کردن خط جداکننده
    read -p "Select an option: " OPTION

    case $OPTION in
        1)
            echo "Enter remote IPv4 address: "
            read REMOTE_IP
            echo "Enter local IPv4 address: "
            read LOCAL_IP
            echo "Enter local IPv6 address: "
            read LOCAL_IPV6

            # حذف محتوای قبلی /etc/rc.local در صورت وجود
            sudo rm -f /etc/rc.local

            # ایجاد و تنظیم تونل
            sudo ip tunnel add tunnel-PD mode sit remote $REMOTE_IP local $LOCAL_IP ttl 126
            sudo ip link set dev tunnel-PD up mtu 1500
            sudo ip addr add $LOCAL_IPV6/64 dev tunnel-PD
            sudo ip link set tunnel-PD mtu 1436
            sudo ip link set tunnel-PD up

            # ایجاد مجدد /etc/rc.local و اضافه کردن تنظیمات جدید
            cat <<EOF | sudo tee /etc/rc.local
#!/bin/bash

ip tunnel add tunnel-PD mode sit remote $REMOTE_IP local $LOCAL_IP ttl 126
ip link set dev tunnel-PD up mtu 1500
ip addr add $LOCAL_IPV6/64 dev tunnel-PD
ip link set tunnel-PD mtu 1436
ip link set tunnel-PD up

exit 0
EOF

            # دادن مجوز اجرایی به rc.local
            sudo chmod +x /etc/rc.local

            echo "Tunnel setup completed and configured in /etc/rc.local"
            read -p "Do you want to reboot the server now? (y/n): " REBOOT_CHOICE
            if [[ "$REBOOT_CHOICE" == "y" ]]; then
                sudo reboot
            fi
            read -p "Press Enter to continue..."
            ;;
        2)
            echo "Assigned Local IPv6 Address:"
            grep -oP 'ip addr add \K[^ ]+' /etc/rc.local 2>/dev/null || echo "No IPv6 assigned."
            read -p "Press Enter to continue..."
            ;;
        3)
            read -p "Are you sure you want to remove the tunnel? (y/n): " CONFIRM_DELETE
            if [[ "$CONFIRM_DELETE" == "y" ]]; then
                echo "Removing tunnel..."
                sudo ip link set tunnel-PD down
                sudo ip tunnel del tunnel-PD
                sudo rm -f /etc/rc.local
                echo "Tunnel removed successfully."
                read -p "Do you want to reboot the server now? (y/n): " REBOOT_CHOICE
                if [[ "$REBOOT_CHOICE" == "y" ]]; then
                    sudo reboot
                fi
            else
                echo "Tunnel removal canceled."
            fi
            read -p "Press Enter to continue..."
            ;;
        4)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option!"
            read -p "Press Enter to continue..."
            ;;
    esac
done
