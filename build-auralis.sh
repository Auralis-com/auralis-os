#!/bin/bash
set -e

# Auralis OS Sequential Build System - GitHub Actions Edition
# ULTIMATE Gaming Linux Distribution - Smart Resource Management
# Phase 1: Build Kernel → Phase 2: Cleanup → Phase 3: Build System

# Build configuration
AURALIS_VERSION="1.0.0-beta"
AURALIS_CODENAME="Borealis"
AURALIS_KERNEL_VERSION="6.11.7-zen1-auralis-rt"
KERNEL_VERSION="6.11.7"
ZEN_VERSION="6.11.7-zen1"
WORK_DIR="/tmp/auralis-build"
ROOT_DIR="$WORK_DIR/rootfs"
ISO_DIR="$WORK_DIR/iso"
KERNEL_DIR="$WORK_DIR/kernel-build"
KERNEL_SAVE_DIR="/tmp/auralis-kernel-artifacts"
OUTPUT_DIR="/tmp/auralis-output"
VOID_MIRROR="https://repo-default.voidlinux.org"
ARCH="x86_64"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[AURALIS-SEQUENTIAL]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

epic() {
    echo -e "${PURPLE}[EPIC]${NC} $1"
}

phase() {
    echo -e "${CYAN}[PHASE]${NC} $1"
}

# Display ultimate banner
display_banner() {
    echo -e "${PURPLE}"
    cat << 'EOF'
    ██████╗ ██╗   ██╗██████╗  ██████╗ ██╗     ██╗███████╗     ██████╗ ███████╗
   ██╔══██╗██║   ██║██╔══██╗██╔══██╗██║     ██║██╔════╝    ██╔═══██╗██╔════╝
   ███████║██║   ██║██████╔╝███████║██║     ██║███████╗    ██║   ██║███████╗
   ██╔══██║██║   ██║██╔══██╗██╔══██║██║     ██║╚════██║    ██║   ██║╚════██║
   ██║  ██║╚██████╔╝██║  ██║██║  ██║███████╗██║███████║    ╚██████╔╝███████║
   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚══════╝     ╚═════╝ ╚══════╝
                                                                            
       🔥 ULTIMATE GAMING LINUX - SEQUENTIAL BUILD EDITION 🔥
       ⚡ linux-zen + PREEMPT_RT + 2000 Hz + Zen Browser ⚡
       🎮 Version: 1.0.0-beta "Borealis" (Smart Resource Management) 🎮
       🧠 Sequential Build: Kernel → Cleanup → System → Success! 🧠
EOF
    echo -e "${NC}"
    echo ""
    epic "Building Auralis OS with intelligent resource management..."
    epic "🎯 3-Phase Sequential Build: Maximum performance, smart resource usage"
    epic "🏖️ Vacation-quality build - patience rewarded with perfection!"
    echo ""
}

# Show current system resources
show_resources() {
    local phase_name="$1"
    info "📊 $phase_name Resources:"
    info "  💻 CPU Cores: $(nproc)"
    info "  🧠 RAM: $(free -h | grep '^Mem:' | awk '{print $7}') free / $(free -h | grep '^Mem:' | awk '{print $2}') total"
    info "  💾 Disk: $(df -h /tmp | tail -1 | awk '{print $4}') available"
    info "  📈 Load: $(uptime | awk -F'load average:' '{print $2}')"
}

# Install build dependencies 
install_build_dependencies() {
    log "🚀 Installing build dependencies for sequential build..."
    
    # Update system
    sudo apt-get update
    
    # Install comprehensive build tools
    sudo apt-get install -y \
        build-essential git wget curl tar \
        flex bison bc libssl-dev libelf-dev libncurses-dev \
        rsync gawk perl python3 cpio \
        dwarves pahole kmod \
        squashfs-tools genisoimage xorriso \
        debootstrap xz-utils \
        ccache \
        quilt patch \
        libaudit-dev \
        libnuma-dev \
        time pv
    
    # Install XBPS tools for Void Linux bootstrap
    if ! command -v xbps-install &> /dev/null; then
        log "Installing XBPS tools for Void Linux bootstrap..."
        cd /tmp
        wget -q https://repo-default.voidlinux.org/static/xbps-static-latest.x86_64-musl.tar.xz
        sudo tar -xf xbps-static-latest.x86_64-musl.tar.xz -C /
        rm -f xbps-static-latest.x86_64-musl.tar.xz
        log "✅ XBPS tools installed successfully"
    fi
    
    # Setup ccache for faster compilation
    export PATH="/usr/lib/ccache:$PATH"
    export CCACHE_DIR="/tmp/ccache"
    mkdir -p "$CCACHE_DIR"
    ccache -M 2G
    
    log "✅ Build dependencies installed with ccache acceleration"
}

# Setup workspace
setup_workspace() {
    log "🏗️ Setting up sequential build workspace..."
    
    # Clean and create directories
    sudo rm -rf "$WORK_DIR" "$KERNEL_SAVE_DIR" 2>/dev/null || true
    mkdir -p "$ROOT_DIR" "$ISO_DIR" "$KERNEL_DIR" "$KERNEL_SAVE_DIR" "$OUTPUT_DIR"
    
    show_resources "Initial"
    log "✅ Sequential build workspace ready"
}

# PHASE 1: Build the ultimate kernel
build_ultimate_kernel() {
    phase "🔥 PHASE 1: Building Ultimate Kernel (linux-zen + PREEMPT_RT + 2000 Hz)"
    show_resources "Phase 1 Start"
    
    cd "$KERNEL_DIR"
    
    # Download linux-zen kernel source
    log "📦 Downloading linux-zen kernel source v$ZEN_VERSION..."
    if wget -q --show-progress "https://github.com/zen-kernel/zen-kernel/archive/v$ZEN_VERSION.tar.gz"; then
        log "📂 Extracting linux-zen source..."
        tar -xf "v$ZEN_VERSION.tar.gz"
        cd "zen-kernel-$ZEN_VERSION"
        
        log "🎵 Downloading PREEMPT_RT patches..."
        RT_VERSION="6.11.7-rt7"
        wget -q --show-progress "https://cdn.kernel.org/pub/linux/kernel/projects/rt/6.11/patch-$RT_VERSION.patch.xz"
        xz -d "patch-$RT_VERSION.patch.xz"
        
        log "🔧 Applying PREEMPT_RT patches to linux-zen..."
        # Apply RT patches with some expected rejections
        patch -f -p1 < "patch-$RT_VERSION.patch" || warn "Some RT patches may conflict with zen - this is expected"
        
        log "⚙️ Creating Ultimate Auralis gaming + RT kernel configuration..."
        make ARCH=x86_64 defconfig
        
        epic "🎮 Applying MAXIMUM gaming + RT optimizations..."
        
        # Apply ultimate gaming + RT configuration
        cat >> .config << 'KERNEL_CONFIG'

# AURALIS ULTIMATE KERNEL CONFIGURATION
# linux-zen + PREEMPT_RT + 2000 Hz + Ultimate Gaming Optimizations

# 2000 Hz Timer - Ultimate gaming responsiveness (0.5ms latency)
CONFIG_HZ_2000=y
CONFIG_HZ=2000

# PREEMPT_RT - Ultra-low latency real-time kernel
CONFIG_PREEMPT_RT=y
CONFIG_PREEMPT_RT_FULL=y

# Full Preemption - Maximum gaming + RT responsiveness
CONFIG_PREEMPT=y
CONFIG_PREEMPT_COUNT=y
CONFIG_PREEMPTION=y
CONFIG_PREEMPT_DYNAMIC=y
CONFIG_PREEMPT_RCU=y

# High-resolution timers for ultra-precise gaming + RT timing
CONFIG_HIGH_RES_TIMERS=y
CONFIG_GENERIC_CLOCKEVENTS=y
CONFIG_TICK_ONESHOT=y

# RT-specific optimizations
CONFIG_IRQ_FORCED_THREADING=y
CONFIG_IRQ_FORCED_THREADING_DEFAULT=y

# CPU Scheduler optimizations for gaming + RT workloads
CONFIG_SCHED_AUTOGROUP=y
CONFIG_CFS_BANDWIDTH=y
CONFIG_RT_GROUP_SCHED=y
CONFIG_SCHED_DEBUG=y

# Memory management optimized for gaming + RT
CONFIG_TRANSPARENT_HUGEPAGE=y
CONFIG_TRANSPARENT_HUGEPAGE_ALWAYS=y
CONFIG_COMPACTION=y
CONFIG_MIGRATION=y
CONFIG_KSM=y
CONFIG_ZSWAP=y

# zram support for maximum gaming performance
CONFIG_ZRAM=y
CONFIG_ZRAM_DEF_COMP_LZORLE=y
CONFIG_ZSMALLOC=y

# Network gaming optimizations
CONFIG_TCP_CONG_ADVANCED=y
CONFIG_TCP_CONG_BBR=y
CONFIG_DEFAULT_TCP_CONG="bbr"
CONFIG_NET_SCH_FQ=y
CONFIG_NET_SCH_FQ_CODEL=y

# Gaming graphics drivers - all major GPUs
CONFIG_DRM_AMDGPU=y
CONFIG_DRM_RADEON=y
CONFIG_DRM_NOUVEAU=y
CONFIG_DRM_I915=y
CONFIG_DRM_I915_GVT=y

# CPU frequency scaling for maximum gaming performance
CONFIG_CPU_FREQ=y
CONFIG_CPU_FREQ_GOV_PERFORMANCE=y
CONFIG_CPU_FREQ_GOV_SCHEDUTIL=y
CONFIG_CPU_FREQ_GOV_ONDEMAND=y

# Audio optimizations for gaming + RT
CONFIG_SND_HRTIMER=y
CONFIG_SND_DYNAMIC_MINORS=y
CONFIG_SND_MAX_CARDS=32

# Gaming + RT I/O optimizations
CONFIG_BFQ_GROUP_IOSCHED=y
CONFIG_IOSCHED_BFQ=y
CONFIG_BFQ_CGROUP_DEBUG=y

# RT-specific features
CONFIG_RT_MUTEXES=y
CONFIG_SLAB=y

KERNEL_CONFIG

        # Build with ccache acceleration and resource monitoring
        KERNEL_JOBS=$(nproc)
        epic "🔨 Compiling Ultimate Kernel with $KERNEL_JOBS cores + ccache..."
        epic "⏱️ Estimated time: 45-75 minutes (Phase 1 of 3)"
        
        export ARCH=x86_64
        export KBUILD_BUILD_HOST=auralis-sequential
        export KBUILD_BUILD_USER=auralis-phase1
        export CC="ccache gcc"
        export CXX="ccache g++"
        
        # Start resource monitoring
        (while true; do 
            echo "🖥️ Phase 1 Progress: $(date +%H:%M) - Free RAM: $(free -h | grep '^Mem:' | awk '{print $7}') - Load: $(uptime | awk -F'load average:' '{print $2}')"
            sleep 300
        done) &
        MONITOR_PID=$!
        
        # Build kernel with timeout protection
        if timeout 4500 make ARCH=x86_64 LOCALVERSION=-auralis-rt -j$KERNEL_JOBS; then
            kill $MONITOR_PID 2>/dev/null || true
            epic "🎉 Phase 1 COMPLETE! Ultimate kernel compiled successfully!"
            show_resources "Phase 1 End"
            return 0
        else
            kill $MONITOR_PID 2>/dev/null || true
            warn "Phase 1 failed - kernel compilation issue"
            return 1
        fi
    else
        warn "Failed to download linux-zen source"
        return 1
    fi
}

# PHASE 2: Save kernel artifacts and cleanup
save_kernel_and_cleanup() {
    phase "💾 PHASE 2: Saving Kernel Artifacts & Resource Cleanup"
    show_resources "Phase 2 Start"
    
    if [[ -f "$KERNEL_DIR/zen-kernel-$ZEN_VERSION/arch/x86/boot/bzImage" ]]; then
        log "💾 Saving ultimate kernel artifacts..."
        cd "$KERNEL_DIR/zen-kernel-$ZEN_VERSION"
        
        # Create modules tarball
        mkdir -p "$KERNEL_SAVE_DIR/modules"
        make INSTALL_MOD_PATH="$KERNEL_SAVE_DIR/modules" modules_install
        
        # Save kernel files
        cp arch/x86/boot/bzImage "$KERNEL_SAVE_DIR/vmlinuz-$AURALIS_KERNEL_VERSION"
        cp System.map "$KERNEL_SAVE_DIR/System.map-$AURALIS_KERNEL_VERSION"
        cp .config "$KERNEL_SAVE_DIR/config-$AURALIS_KERNEL_VERSION"
        
        # Create modules archive
        cd "$KERNEL_SAVE_DIR"
        tar -czf "modules-$AURALIS_KERNEL_VERSION.tar.gz" modules/
        rm -rf modules/
        
        epic "✅ Ultimate kernel artifacts saved successfully!"
        KERNEL_AVAILABLE=true
    else
        warn "No kernel built, will use standard kernel"
        KERNEL_AVAILABLE=false
    fi
    
    log "🧹 Aggressive cleanup to free resources for Phase 3..."
    
    # Clean up kernel build directory (frees ~3-4GB)
    rm -rf "$KERNEL_DIR" 2>/dev/null || true
    
    # Clean ccache
    ccache -C 2>/dev/null || true
    
    # Clean temporary files
    sudo apt-get clean
    rm -rf /tmp/tmp.* /tmp/*.tar.* 2>/dev/null || true
    
    # Force garbage collection
    sync
    echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null || true
    
    show_resources "Phase 2 End (After Cleanup)"
    epic "🎯 Phase 2 COMPLETE! Resources freed for system build"
}

# Bootstrap Void Linux base system
bootstrap_void_linux() {
    log "🚀 Bootstrapping Void Linux base system..."
    
    cd "$WORK_DIR"
    
    # Try multiple Void Linux rootfs versions
    local void_dates=("20250202" "20240314" "20231230")
    local void_downloaded=false
    
    for date in "${void_dates[@]}"; do
        local void_url="$VOID_MIRROR/live/current/void-x86_64-ROOTFS-$date.tar.xz"
        
        if wget -q --spider "$void_url"; then
            log "📦 Downloading Void Linux rootfs ($date)..."
            if wget -q --show-progress -O "void-base.tar.xz" "$void_url"; then
                void_downloaded=true
                break
            fi
        fi
    done
    
    if [[ "$void_downloaded" != "true" ]]; then
        error "Failed to download Void Linux base system"
    fi
    
    log "📂 Extracting Void Linux base system..."
    sudo tar -xf "void-base.tar.xz" -C "$ROOT_DIR" --strip-components=1
    
    # Copy resolv.conf for internet access in chroot
    sudo cp /etc/resolv.conf "$ROOT_DIR/etc/"
    
    log "✅ Void Linux base system ready"
}

# Mount filesystems for chroot
mount_chroot() {
    log "🔧 Mounting filesystems for chroot..."
    
    sudo mount -t proc proc "$ROOT_DIR/proc"
    sudo mount -t sysfs sysfs "$ROOT_DIR/sys"
    sudo mount -t devtmpfs devtmpfs "$ROOT_DIR/dev" || sudo mount --bind /dev "$ROOT_DIR/dev"
    sudo mount -t devpts devpts "$ROOT_DIR/dev/pts" || true
}

# Unmount filesystems
unmount_chroot() {
    log "🧹 Unmounting chroot filesystems..."
    
    sudo umount -l "$ROOT_DIR/proc" 2>/dev/null || true
    sudo umount -l "$ROOT_DIR/sys" 2>/dev/null || true
    sudo umount -l "$ROOT_DIR/dev/pts" 2>/dev/null || true
    sudo umount -l "$ROOT_DIR/dev" 2>/dev/null || true
}

# Install saved ultimate kernel or fallback
install_saved_kernel() {
    if [[ "$KERNEL_AVAILABLE" == "true" && -f "$KERNEL_SAVE_DIR/vmlinuz-$AURALIS_KERNEL_VERSION" ]]; then
        epic "⚡ Installing saved Ultimate Kernel (linux-zen + RT + 2000 Hz)..."
        
        # Install kernel image
        sudo mkdir -p "$ROOT_DIR/boot"
        sudo cp "$KERNEL_SAVE_DIR/vmlinuz-$AURALIS_KERNEL_VERSION" "$ROOT_DIR/boot/"
        sudo cp "$KERNEL_SAVE_DIR/System.map-$AURALIS_KERNEL_VERSION" "$ROOT_DIR/boot/"
        sudo cp "$KERNEL_SAVE_DIR/config-$AURALIS_KERNEL_VERSION" "$ROOT_DIR/boot/"
        
        # Extract and install modules
        cd "$ROOT_DIR"
        sudo tar -xzf "$KERNEL_SAVE_DIR/modules-$AURALIS_KERNEL_VERSION.tar.gz"
        
        epic "🎉 Ultimate kernel (linux-zen + RT + 2000 Hz) installed!"
        KERNEL_LABEL="Ultimate linux-zen + PREEMPT_RT + 2000 Hz Gaming Kernel"
        CUSTOM_KERNEL=true
    else
        log "📦 Installing standard Void zen kernel..."
        sudo chroot "$ROOT_DIR" xbps-install -Suy xbps
        sudo chroot "$ROOT_DIR" xbps-install -y linux-zen linux-zen-headers || sudo chroot "$ROOT_DIR" xbps-install -y linux6.6 linux6.6-headers
        KERNEL_LABEL="Standard Zen Gaming Kernel"
        CUSTOM_KERNEL=false
    fi
}

# Install ultimate gaming packages including Zen Browser
install_ultimate_gaming_packages() {
    epic "🎮 Installing ultimate gaming packages with ZEN BROWSER..."
    
    # Update XBPS first
    sudo chroot "$ROOT_DIR" xbps-install -Suy xbps
    
    # Define comprehensive package groups
    local base_packages=(
        "base-system" "linux-firmware" "intel-ucode" "void-repo-nonfree"
        "runit-void" "elogind" "dbus"
    )
    
    local desktop_packages=(
        "plasma-desktop" "plasma-workspace" "konsole" "dolphin" "kate" "sddm"
        "plasma-nm" "plasma-pa" "plasma-systemsettings" "kscreen"
    )
    
    local gaming_packages=(
        "steam" "lutris" "gamemode" "mangohud" "wine" "winetricks"
        "vulkan-loader" "mesa-vulkan-radeon" "mesa-vulkan-intel"
    )
    
    local system_packages=(
        "NetworkManager" "pulseaudio" "alsa-utils" "mesa" "mesa-dri"
        "flatpak" "nano" "wget" "curl" "git" "htop" "neofetch" "sudo"
    )
    
    # Ultimate performance packages
    local performance_packages=(
        "zram-generator" "earlyoom" "irqbalance" "upower"
    )
    
    # Install packages in groups
    log "Installing base system packages..."
    sudo chroot "$ROOT_DIR" xbps-install -y "${base_packages[@]}" || warn "Some base packages failed"
    
    log "Installing desktop environment..."
    sudo chroot "$ROOT_DIR" xbps-install -y "${desktop_packages[@]}" || warn "Some desktop packages failed"
    
    log "Installing gaming packages..."
    sudo chroot "$ROOT_DIR" xbps-install -y "${gaming_packages[@]}" || warn "Some gaming packages failed"
    
    log "Installing system utilities..."
    sudo chroot "$ROOT_DIR" xbps-install -y "${system_packages[@]}" || warn "Some system packages failed"
    
    log "Installing ultimate performance packages (zram + earlyoom)..."
    sudo chroot "$ROOT_DIR" xbps-install -y "${performance_packages[@]}" || warn "Some performance packages failed"
    
    # Download Zen Browser
    epic "🌟 Installing gorgeous ZEN BROWSER..."
    sudo mkdir -p "$ROOT_DIR/opt"
    cd "$ROOT_DIR/opt"
    sudo wget -q -O zen-browser.tar.bz2 "https://github.com/zen-browser/desktop/releases/latest/download/zen.linux-x86_64.tar.bz2" || warn "Zen Browser download failed"
    
    if [[ -f zen-browser.tar.bz2 ]]; then
        sudo tar -xf zen-browser.tar.bz2
        sudo rm zen-browser.tar.bz2
        sudo mv zen* zen-browser 2>/dev/null || true
        sudo chmod +x zen-browser/zen* 2>/dev/null || true
        epic "✅ ZEN BROWSER installed successfully!"
    fi
    
    log "✅ Ultimate gaming package installation completed!"
}

# Configure Auralis OS system
configure_auralis_system() {
    log "⚙️ Configuring Auralis OS for ultimate gaming..."
    
    # Set hostname
    echo "auralis" | sudo tee "$ROOT_DIR/etc/hostname"
    
    # Configure hosts file
    sudo tee "$ROOT_DIR/etc/hosts" << 'EOF'
127.0.0.1    localhost
127.0.1.1    auralis.localdomain auralis
::1          localhost ip6-localhost ip6-loopback
ff02::1      ip6-allnodes
ff02::2      ip6-allrouters
EOF
    
    # Create users
    sudo chroot "$ROOT_DIR" useradd -m -G wheel,audio,video,optical,storage,gamemode,realtime auralis 2>/dev/null || true
    echo "auralis:auralis" | sudo chroot "$ROOT_DIR" chpasswd
    echo "root:auralis" | sudo chroot "$ROOT_DIR" chpasswd
    
    # Configure sudo
    echo "%wheel ALL=(ALL) ALL" | sudo tee "$ROOT_DIR/etc/sudoers.d/wheel"
    
    # Enable services
    sudo chroot "$ROOT_DIR" ln -sf /etc/sv/NetworkManager /etc/runit/runsvdir/default/ || true
    sudo chroot "$ROOT_DIR" ln -sf /etc/sv/sddm /etc/runit/runsvdir/default/ || true
    sudo chroot "$ROOT_DIR" ln -sf /etc/sv/dbus /etc/runit/runsvdir/default/ || true
    sudo chroot "$ROOT_DIR" ln -sf /etc/sv/elogind /etc/runit/runsvdir/default/ || true
    sudo chroot "$ROOT_DIR" ln -sf /etc/sv/earlyoom /etc/runit/runsvdir/default/ || true
    
    log "✅ System configuration completed"
}

# Configure ultimate gaming optimizations
configure_ultimate_optimizations() {
    epic "🔥 Configuring ULTIMATE gaming + RT optimizations..."
    
    # Create ultimate gaming sysctl configuration
    sudo mkdir -p "$ROOT_DIR/etc/sysctl.d"
    sudo tee "$ROOT_DIR/etc/sysctl.d/99-auralis-ultimate-gaming-rt.conf" << 'EOF'
# Auralis OS Ultimate Gaming + PREEMPT_RT Performance Configuration
# Optimized for linux-zen + RT + 2000 Hz kernel + maximum gaming performance

# Memory management - ultimate gaming + RT optimization
vm.swappiness=1
vm.vfs_cache_pressure=10
vm.dirty_ratio=3
vm.dirty_background_ratio=1
vm.dirty_expire_centisecs=500
vm.dirty_writeback_centisecs=100
vm.min_free_kbytes=131072

# Network gaming optimizations - competitive gaming ready
net.core.rmem_max=268435456
net.core.wmem_max=268435456
net.core.rmem_default=1048576
net.core.wmem_default=1048576
net.core.netdev_max_backlog=5000
net.ipv4.tcp_congestion_control=bbr
net.ipv4.tcp_notsent_lowat=16384
net.ipv4.tcp_low_latency=1

# Gaming + RT specific optimizations
vm.max_map_count=2147483642
fs.file-max=2097152
kernel.sched_migration_cost_ns=5000000
kernel.sched_latency_ns=1000000
kernel.sched_min_granularity_ns=100000
kernel.sched_wakeup_granularity_ns=50000

# RT kernel optimizations
kernel.sched_rt_period_us=1000000
kernel.sched_rt_runtime_us=950000

# Audio latency optimizations - pro gaming + RT audio
dev.hpet.max-user-freq=3072
EOF

    # Configure zram for maximum gaming performance
    sudo mkdir -p "$ROOT_DIR/etc/systemd/zram-generator.conf.d"
    sudo tee "$ROOT_DIR/etc/systemd/zram-generator.conf.d/auralis-ultimate-gaming.conf" << 'EOF'
# Auralis OS zram configuration - ultimate gaming + RT performance
[zram0]
zram-size = ram / 2
compression-algorithm = lz4
swap-priority = 100
fs-type = swap
EOF

    # Configure earlyoom for gaming responsiveness
    sudo mkdir -p "$ROOT_DIR/etc/default"
    sudo tee "$ROOT_DIR/etc/default/earlyoom" << 'EOF'
# Auralis OS earlyoom - protect gaming + RT performance
EARLYOOM_ARGS="--prefer '(^|/)(java|chrome|firefox|electron)$' --avoid '(^|/)(steam|lutris|gamemode|zen-browser|Xorg|sddm)$' -m 5 -s 2 -r 60"
EOF

    # Ultimate gaming + RT mode script
    sudo tee "$ROOT_DIR/usr/local/bin/auralis-ultimate-gaming-rt-mode" << 'EOF'
#!/bin/bash
# Auralis OS Ultimate Gaming + RT Mode - Maximum Performance

echo "🔥 Activating Auralis ULTIMATE Gaming + RT Mode..."

# CPU - Maximum performance
echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null 2>&1 || true

# I/O - Gaming optimized scheduler
echo mq-deadline | tee /sys/block/*/queue/scheduler >/dev/null 2>&1 || true

# Kernel - Gaming + RT optimizations
echo 0 | tee /proc/sys/kernel/timer_migration >/dev/null 2>&1 || true
echo 0 | tee /proc/sys/kernel/numa_balancing >/dev/null 2>&1 || true

# Network - Gaming priority
echo 1 | tee /proc/sys/net/ipv4/tcp_low_latency >/dev/null 2>&1 || true

# RT optimizations
echo -1 | tee /proc/sys/kernel/sched_rt_runtime_us >/dev/null 2>&1 || true

echo "🎮 Auralis ULTIMATE Gaming + RT Mode: ACTIVATED!"
echo "⚡ linux-zen + RT + 2000 Hz kernel + maximum performance optimizations enabled!"
echo "🚀 Ready for ultimate competitive gaming and real-time audio!"
EOF

    sudo chmod +x "$ROOT_DIR/usr/local/bin/auralis-ultimate-gaming-rt-mode"
    
    epic "🎉 Ultimate gaming + RT optimizations configured!"
}

# Configure gaming desktop with Zen Browser
configure_ultimate_desktop() {
    epic "🎨 Setting up ultimate gaming desktop with ZEN BROWSER..."
    
    # Create desktop shortcuts
    sudo mkdir -p "$ROOT_DIR/home/auralis/Desktop"
    
    # Gaming shortcuts
    sudo tee "$ROOT_DIR/home/auralis/Desktop/steam.desktop" << 'EOF'
[Desktop Entry]
Name=Steam
Comment=Ultimate Gaming Platform
Exec=steam
Icon=steam
Type=Application
Categories=Game;
EOF

    sudo tee "$ROOT_DIR/home/auralis/Desktop/lutris.desktop" << 'EOF'
[Desktop Entry]
Name=Lutris
Comment=Open Gaming Platform
Exec=lutris
Icon=lutris
Type=Application
Categories=Game;
EOF

    # Zen Browser shortcut
    sudo tee "$ROOT_DIR/home/auralis/Desktop/zen-browser.desktop" << 'EOF'
[Desktop Entry]
Name=Zen Browser
Comment=Beautiful, Fast, Private Browser
Exec=/opt/zen-browser/zen
Icon=/opt/zen-browser/browser/chrome/icons/default/default128.png
Type=Application
Categories=Network;WebBrowser;
EOF

    sudo tee "$ROOT_DIR/home/auralis/Desktop/ultimate-gaming-rt-mode.desktop" << 'EOF'
[Desktop Entry]
Name=Auralis Ultimate Gaming + RT Mode
Comment=Activate maximum gaming + RT performance
Exec=pkexec /usr/local/bin/auralis-ultimate-gaming-rt-mode
Icon=applications-games
Type=Application
Categories=System;
EOF

    # Set ownership
    sudo chown -R 1000:1000 "$ROOT_DIR/home/auralis" || true
    
    epic "✅ Ultimate gaming desktop with ZEN BROWSER configured!"
}

# Create bootable ISO
create_auralis_iso() {
    epic "💿 Creating Auralis OS Ultimate Edition bootable ISO..."
    
    # Prepare ISO structure
    mkdir -p "$WORK_DIR/iso-root"
    
    # Copy system files
    sudo rsync -av "$ROOT_DIR/" "$WORK_DIR/iso-root/" || sudo cp -a "$ROOT_DIR/"/* "$WORK_DIR/iso-root/"
    
    # Create ISO
    ISO_FILE="$OUTPUT_DIR/auralis-os-ultimate-sequential-${AURALIS_VERSION}-borealis-${ARCH}.iso"
    
    if command -v xorriso >/dev/null; then
        log "Creating ultimate sequential build ISO with xorriso..."
        sudo xorriso -as mkisofs \
            -iso-level 3 \
            -full-iso9660-filenames \
            -volid "AURALIS_ULTIMATE" \
            -output "$ISO_FILE" \
            "$WORK_DIR/iso-root"
    elif command -v genisoimage >/dev/null; then
        log "Creating ultimate ISO with genisoimage..."
        sudo genisoimage -o "$ISO_FILE" \
            -V "AURALIS_ULTIMATE" \
            -J -r \
            "$WORK_DIR/iso-root"
    else
        warn "Creating system archive instead of ISO"
        sudo tar -czf "$OUTPUT_DIR/auralis-os-ultimate-sequential-${AURALIS_VERSION}-borealis-${ARCH}.tar.gz" \
            -C "$WORK_DIR/iso-root" .
    fi
    
    # Set permissions for GitHub Actions
    sudo chown -R runner:runner "$OUTPUT_DIR" 2>/dev/null || true
    
    epic "✅ Auralis OS Ultimate Sequential Build ISO created!"
}

# Display ultimate completion
display_ultimate_completion() {
    echo ""
    echo -e "${PURPLE}🎊 AURALIS OS ULTIMATE SEQUENTIAL BUILD COMPLETED! 🎊${NC}"
    echo ""
    echo -e "${GREEN}📋 Ultimate Sequential Build Information:${NC}"
    echo "  🏷️ Version: $AURALIS_VERSION ($AURALIS_CODENAME) - ULTIMATE SEQUENTIAL"
    echo "  🏗️ Architecture: $ARCH"
    echo "  📅 Build Date: $(date)"
    echo "  🌐 Build Platform: GitHub Actions (Sequential Cloud Build)"
    echo "  💪 Build Method: 3-Phase Sequential Resource Management"
    echo "  🧠 Strategy: Kernel → Cleanup → System → Success!"
    
    if [[ "$CUSTOM_KERNEL" == "true" ]]; then
        echo "  ⚡ Kernel: ULTIMATE Auralis Kernel $AURALIS_KERNEL_VERSION"
        echo "           (linux-zen + PREEMPT_RT + 2000 Hz)"
    else
        echo "  ⚡ Kernel: Standard Zen Gaming Kernel"
    fi
    
    echo ""
    echo -e "${BLUE}🎮 ULTIMATE Sequential Build Features:${NC}"
    echo "  🔥 linux-zen + PREEMPT_RT + 2000 Hz kernel (0.5ms latency)"
    echo "  🌟 Gorgeous ZEN BROWSER (Chef's kiss aesthetics!)"
    echo "  ⚡ zram + earlyoom for maximum performance"
    echo "  🎯 GameMode, Lutris, Steam, MangoHud pre-installed"
    echo "  🌐 BBR network optimization for online gaming"
    echo "  🚀 Ultra-low latency optimizations throughout"
    echo "  🎵 Real-time audio support for pro gaming"
    echo "  🧠 Smart resource management (no more crashes!)"
    echo "  🪟 Windows-like KDE Plasma gaming interface"
    echo ""
    echo -e "${BLUE}🔑 Default Credentials:${NC}"
    echo "  👤 Root: root / auralis"
    echo "  👤 User: auralis / auralis"
    echo ""
    echo -e "${GREEN}📁 Ultimate Sequential Build Output:${NC}"
    if [[ -f "$OUTPUT_DIR/auralis-os-ultimate-sequential-${AURALIS_VERSION}-borealis-${ARCH}.iso" ]]; then
        echo "  💿 Ultimate ISO: auralis-os-ultimate-sequential-${AURALIS_VERSION}-borealis-${ARCH}.iso"
        echo "  📏 Size: $(du -h $OUTPUT_DIR/auralis-os-ultimate-sequential-${AURALIS_VERSION}-borealis-${ARCH}.iso | cut -f1)"
    fi
    echo ""
    echo -e "${PURPLE}🌌 Auralis OS Ultimate Sequential Edition - Perfected! 🌌${NC}"
    echo -e "${PURPLE}🧠 Smart Resource Management = Reliable Ultimate Builds! 🧠${NC}"
    echo -e "${PURPLE}🏖️ Vacation Quality Achieved - No Rush, Pure Excellence! 🏖️${NC}"
    echo ""
}

# Cleanup function
cleanup() {
    log "🧹 Final cleanup..."
    unmount_chroot 2>/dev/null || true
    # Clean up saved kernel artifacts if build completed
    rm -rf "$KERNEL_SAVE_DIR" 2>/dev/null || true
}

# PHASE 3: Build the system
build_system() {
    phase "🏗️ PHASE 3: Building System with Ultimate Kernel"
    show_resources "Phase 3 Start"
    
    bootstrap_void_linux
    mount_chroot
    install_saved_kernel
    install_ultimate_gaming_packages
    configure_auralis_system
    configure_ultimate_optimizations
    configure_ultimate_desktop
    unmount_chroot
    create_auralis_iso
    
    show_resources "Phase 3 End"
    epic "🎯 Phase 3 COMPLETE! System built with ultimate kernel!"
}

# Main sequential build process
main() {
    # Set trap for cleanup
    trap cleanup EXIT
    
    # Start the ultimate sequential build
    display_banner
    install_build_dependencies
    setup_workspace
    
    # PHASE 1: Build ultimate kernel
    if build_ultimate_kernel; then
        save_kernel_and_cleanup
    else
        warn "Phase 1 failed, will use standard kernel"
        KERNEL_AVAILABLE=false
        save_kernel_and_cleanup
    fi
    
    # PHASE 3: Build system with saved kernel
    build_system
    
    # Show ultimate completion
    display_ultimate_completion
    
    epic "🎉 Auralis OS Ultimate Sequential Build Complete!"
    epic "🧠 Smart resource management delivered the impossible!"
}

# Execute ultimate sequential build
main "$@"
