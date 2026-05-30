#!/usr/bin/env python3
"""
闪讯 Windows MSIX 签名证书生成脚本

用法（管理员权限）：
  python scripts/build_center/windows/gen_cert.py

生成后：
  - 证书文件：scripts/build_center/windows/flash_im.pfx
  - 密码：flash123
  - 证书安装到本机"受信任的人"存储区
"""

import os
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PFX_PATH = os.path.join(SCRIPT_DIR, "flash_im.pfx")
SUBJECT = "CN=toly, O=toly1994, C=CN"
DEFAULT_PASSWORD = "flash123"


def info(msg):
    print(f"\033[34m[INFO]\033[0m {msg}")

def ok(msg):
    print(f"\033[32m[OK]\033[0m {msg}")

def fail(msg):
    print(f"\033[31m[FAIL]\033[0m {msg}")
    sys.exit(1)

def run_ps(script):
    r = subprocess.run(
        ["powershell", "-ExecutionPolicy", "Bypass", "-Command", script],
        capture_output=True, text=True
    )
    if r.returncode != 0:
        fail(f"PowerShell 执行失败:\n{r.stderr}")
    return r.stdout.strip()


def main():
    # 支持自定义密码：python gen_cert.py [密码]
    password = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_PASSWORD

    print()
    info(f"Subject: {SUBJECT}")
    info(f"密码: {password}")
    info(f"输出: {PFX_PATH}")
    print()

    # 创建自签名证书
    info("创建自签名证书...")
    thumbprint = run_ps(f'''
        $cert = New-SelfSignedCertificate `
            -Type Custom `
            -Subject "{SUBJECT}" `
            -KeyUsage DigitalSignature `
            -FriendlyName "FlashIM MSIX Signing" `
            -CertStoreLocation "Cert:\\CurrentUser\\My" `
            -TextExtension @("2.5.29.37={{text}}1.3.6.1.5.5.7.3.3", "2.5.29.19={{text}}") `
            -NotAfter (Get-Date).AddYears(5)
        $cert.Thumbprint
    ''')
    ok(f"证书已创建，指纹: {thumbprint}")

    # 导出 .pfx
    info("导出 .pfx ...")
    run_ps(f'''
        $pw = ConvertTo-SecureString -String "{password}" -Force -AsPlainText
        Export-PfxCertificate -Cert "Cert:\\CurrentUser\\My\\{thumbprint}" -FilePath "{PFX_PATH}" -Password $pw | Out-Null
    ''')
    ok(f"已导出: {PFX_PATH} (密码: {password})")

    # 安装到受信任存储区（需要管理员权限，失败不阻塞）
    info("安装证书到本机受信任存储区...")
    r = subprocess.run(
        ["certutil", "-p", password, "-importpfx", "TrustedPeople", PFX_PATH],
        capture_output=True, text=True
    )
    if r.returncode == 0:
        ok("证书已安装到受信任存储区")
    else:
        print(f"\033[33m[WARN]\033[0m 安装证书需要管理员权限，请用管理员终端运行：")
        print(f'  certutil -p {password} -importpfx TrustedPeople "{PFX_PATH}"')

    print()
    ok("完成! 在 msix_config 中配置：")
    print(f"  certificate_path: scripts/build_center/windows/flash_im.pfx")
    print(f"  certificate_password: {password}")
    print(f"  publisher: {SUBJECT}")


if __name__ == "__main__":
    main()
