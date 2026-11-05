# usage: bump.sh N  (sets build 1.0-devN in export_presets, CLAUDE.md, README)
cd "$(dirname "$0")/../.."   # the project folder
n=$1
sed -i "s/^version\/code=[0-9]*$/version\/code=$n/; s/^version\/name=\"1.0-dev[0-9]*\"$/version\/name=\"1.0-dev$n\"/" export_presets.cfg
sed -i "s/Current: dev[0-9]* (code [0-9]*)\./Current: dev$n (code $n)./" CLAUDE.md
sed -i "s/^Build 1.0-dev[0-9]* (version\/code=[0-9]* and version\/name=\"1.0-dev[0-9]*\"/Build 1.0-dev$n (version\/code=$n and version\/name=\"1.0-dev$n\"/" README-RUDY.md
grep "version/name" export_presets.cfg
