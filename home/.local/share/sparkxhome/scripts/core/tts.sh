#export SPARKX_TTS_MODEL=tts_models/en/ljspeech/glow-tts
export SPARKX_TTS_MODEL=tts_models/en/jenny/jenny

sparkx-tts() {
    tts --text "$@" --model_name "$SPARKX_TTS_MODEL" --use_cuda true --pipe_out | aplay 2>/dev/null
}

sparkx-tts-continuous() {
    local to_tts=""
    local model=$SPARKX_TTS_MODEL

    sparkx-tts-setup
    clear
    echo "Welcome to SparkX TTS CLI. Type !quit to exit. To change models use !model model. To List models type !list"
    echo "Active Model: $SPARKX_TTS_MODEL"
    while [[ "$end" != "true" ]]; do
        read -p "tts: " to_tts
        if [[ "$to_tts" == "!quit" ]]; then
            break
        elif [[ "$to_tts" =~ ^!model.* ]]; then
            model=${to_tts#!model }
            continue
        elif [[ "$to_tts" =~ ^!list.* ]]; then
            tts --list_models
            continue
        fi
        SPARKX_TTS_MODEL=$model sparkx-tts "$to_tts"
    done 
}

sparkx-tts-setup() {
    if [[ "$CONDA_PREFIX" == *"env/tts"* ]]; then
        return 0
    else
        conda-activate
        local envs=`conda env list --json`
        if [[ "$envs" == *"envs/tts"* ]]; then
            conda activate tts
        else
            conda create -y -n tts PYTHON=3.10
            conda activate tts
            pip install tts
        fi
    fi
}
