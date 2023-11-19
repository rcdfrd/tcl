# Tiny Core Linux LiveCD with OpenSSH

This project aims to provide a minimalistic Tiny Core Linux LiveCD with OpenSSH pre-installed. Tiny Core Linux is a lightweight Linux distribution designed for simplicity and speed, making it an excellent choice for embedded systems, virtual machines, or other scenarios where resource efficiency is crucial.

## Features

- **Tiny Core Linux Base:** Utilizes the Tiny Core Linux distribution as the foundation, ensuring a lightweight and minimalistic environment.

- **OpenSSH:** OpenSSH is pre-installed, allowing secure remote access to the LiveCD environment. This is particularly useful for headless systems or situations where a graphical interface is not required.

## Usage

1. **Download the LiveCD Image from Actions**

2. **Boot from the LiveCD:** Create a bootable medium using the downloaded image and boot your system from it.

3. **Access via SSH:**
   - Username: `tc` (Tiny Core default user)
   - Password: `toor` (Change this immediately after logging in)

   ```bash
   ssh tc@<your-livecd-ip>

4. **Use TCL in VPS**

   ```bash
   bash <(wget -qO- https://github.com/rcdfrd/tcl/raw/main/install.sh)
   ```

## Build Instructions

If you want to build the LiveCD yourself, follow these steps:

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/rcdfrd/tcl.git
   cd tcl
   ```

2. **Build the LiveCD:**

   ```bash
   bash main.sh
   ```

   This script will handle the process of creating the Tiny Core Linux LiveCD with OpenSSH.
