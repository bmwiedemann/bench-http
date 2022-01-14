Scan all openSUSE mirrors from various places around the world.

inspired by [this reddit discussion](https://www.reddit.com/r/openSUSE/comments/r82tyg/is_zypper_slow_for_you/)


## Usage
```bash
git clone https://github.com/bmwiedemann/bench-http
cd bench-http
zypper -n in perl-IO-Socket-INET6
./benchlist.sh | tee out
sudo findbestmirror.pl < out
```
