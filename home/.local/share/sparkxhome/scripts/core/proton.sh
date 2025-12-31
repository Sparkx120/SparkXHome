function activate_proton() {
    export W="~/.steam/steam/steamapps/common/Proton - Experimental/files"
    export WINEVERPATH=$W
    export PATH=$W/bin:$PATH
    export WINESERVER=$W/bin/wineserver
    export WINELOADER=$W/bin/wine
    export WINEDLLPATH=$W/lib/wine/fakedlls
    export LD_LIBRARY_PATH="$W/lib:$LD_LIBRARY_PATH"
    export WINEPREFIX=~/proton_extern_prefix
}
