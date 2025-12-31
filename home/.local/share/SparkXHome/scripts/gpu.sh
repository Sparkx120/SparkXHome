#!/bin/bash

#!/bin/bash

#gpu="0000:06:00.0"
#aud="0000:06:00.1"
#gpu="2216:06:00.0"
#aud="1aef:06:00.1"
#gpu_vd="$(cat /sys/bus/pci/devices/$gpu/vendor) $(cat /sys/bus/pci/devices/$gpu/device)"
#aud_vd="$(cat /sys/bus/pci/devices/$aud/vendor) $(cat /sys/bus/pci/devices/$aud/device)"

function sparkx-gpu-iommu-groups {
    shopt -s nullglob
    for g in $(find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V); do
        echo "IOMMU Group ${g##*/}:"
        for d in $g/devices/*; do
            echo -e "\t$(lspci -nns ${d##*/})"
        done;
    done;
}

function sparkx-gpu-bind-vfio {
  echo "$gpu" > "/sys/bus/pci/devices/$gpu/driver/unbind"
  #echo "$aud" > "/sys/bus/pci/devices/$aud/driver/unbind"
  echo "$gpu_vd" > /sys/bus/pci/drivers/vfio-pci/new_id
  #echo "$aud_vd" > /sys/bus/pci/drivers/vfio-pci/new_id
}
 
function sparkx-gpu-unbind-vfio {
  echo "$gpu_vd" > "/sys/bus/pci/drivers/vfio-pci/remove_id"
  #echo "$aud_vd" > "/sys/bus/pci/drivers/vfio-pci/remove_id"
  echo 1 > "/sys/bus/pci/devices/$gpu/remove"
  #echo 1 > "/sys/bus/pci/devices/$aud/remove"
  echo 1 > "/sys/bus/pci/rescan"
}
