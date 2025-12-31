#!/usr/bin/env bash
# Derived from: https://gist.github.com/acrisci/b264c4b8e7f93a21c13065d9282dfa4a 
sparkx-set-default-media-player() {
	help_string=$(cat <<EOF
Usage: sparkx-set-default-media-player [-h|-l] APPLICATION
	Set a video player as the default.
Example:
	# List candidate desktop files for media players.
	sparkx-set-default-media-player -l
	# Pick one and set it as the default.
	sparkx-set-default-media-player mpv.desktop
See Also:
	<https://specifications.freedesktop.org/mime-apps-spec/latest/index.html>
EOF
	)

	hash xdg-mime || {
		echo "sparkx-set-default-media-player: xdg-mime is required to run this script (usually provided by xdg-utils package)."
		return 127
	}

	desktop_path=(/usr/share/applications /usr/local/share/applications)
	desktop=$1
	
	list_media_players() {
		for desktop_dir in ${desktop_path[@]}; do
			entries=$(find ${desktop_dir} -name "*.desktop")
			if [[ $? != 0 ]]; then
				return $?
			fi
			for entry in ${entries[@]}; do
				if [[ ! -f ${entry} ]]; then
					continue
				fi

				grep -qE '^MimeType=.*video\/|MimeType=.*audio\/' ${entry}
				if [[ $? = 0 ]]; then
					echo $(basename ${entry})
				fi
			done
		done
	}

	if [[ -z ${desktop} ]] || [[ ${desktop} = "-h" ]] || [[ ${desktop} = "--help" ]]; then
		echo "$help_string"
		return 0
	fi
    
    echo ${desktop}
	if [[ ${desktop} = "-l" ]]; then
		list_media_players
		return 0
	fi

    if ! [[ ${desktop} =~ .desktop$ ]]; then
		echo -e "${help_string}\n"
		>&2 echo "sparkx-set-default-media-player Expected a *.desktop file for the first argument."
		return 1
	fi


	found=0
	for desktop_dir in ${desktop_path[@]}; do
		if [[ -n $(find ${desktop_dir} -name ${desktop}) ]]; then
			found=1
			break
		fi
	done

	if [[ ${found} == 0 ]]; then
		>&2 echo "sparkx-set-default-media-player: WARNING: desktop file does not exist: ${desktop}"
	fi

	mimetypes=(
		application/ogg application/x-ogg application/mxf application/sdp
		application/smil application/x-smil application/streamingmedia
		application/x-streamingmedia application/vnd.rn-realmedia
		application/vnd.rn-realmedia-vbr audio/aac audio/x-aac
		audio/vnd.dolby.heaac.1 audio/vnd.dolby.heaac.2 audio/aiff audio/x-aiff
		audio/m4a audio/x-m4a application/x-extension-m4a audio/mp1 audio/x-mp1
		audio/mp2 audio/x-mp2 audio/mp3 audio/x-mp3 audio/mpeg audio/mpeg2
		audio/mpeg3 audio/mpegurl audio/x-mpegurl audio/mpg audio/x-mpg
		audio/rn-mpeg audio/musepack audio/x-musepack audio/ogg audio/scpls
		audio/x-scpls audio/vnd.rn-realaudio audio/wav audio/x-pn-wav
		audio/x-pn-windows-pcm audio/x-realaudio audio/x-pn-realaudio
		audio/x-ms-wma audio/x-pls audio/x-wav video/mpeg video/x-mpeg2
		video/x-mpeg3 video/mp4v-es video/x-m4v video/mp4
		application/x-extension-mp4 video/divx video/vnd.divx video/msvideo
		video/x-msvideo video/ogg video/quicktime video/vnd.rn-realvideo
		video/x-ms-afs video/x-ms-asf audio/x-ms-asf application/vnd.ms-asf
		video/x-ms-wmv video/x-ms-wmx video/x-ms-wvxvideo video/x-avi video/avi
		video/x-flic video/fli video/x-flc video/flv video/x-flv video/x-theora
		video/x-theora+ogg video/x-matroska video/mkv audio/x-matroska
		application/x-matroska video/webm audio/webm audio/vorbis audio/x-vorbis
		audio/x-vorbis+ogg video/x-ogm video/x-ogm+ogg application/x-ogm
		application/x-ogm-audio application/x-ogm-video application/x-shorten
		audio/x-shorten audio/x-ape audio/x-wavpack audio/x-tta audio/AMR audio/ac3
		audio/eac3 audio/amr-wb video/mp2t audio/flac audio/mp4
		application/x-mpegurl video/vnd.mpegurl application/vnd.apple.mpegurl
		audio/x-pn-au video/3gp video/3gpp video/3gpp2 audio/3gpp audio/3gpp2
		video/dv audio/dv audio/opus audio/vnd.dts audio/vnd.dts.hd audio/x-adpcm
		application/x-cue audio/m3u
	)

	xdg-mime default ${desktop} ${mimetypes[@]}
	return $?
}
