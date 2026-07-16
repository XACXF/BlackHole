cmake_minimum_required(VERSION 3.22)
project(XACVST VERSION 1.0.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_OSX_DEPLOYMENT_TARGET "10.15" CACHE STRING "" FORCE)
set(CMAKE_OSX_ARCHITECTURES "x86_64" CACHE STRING "" FORCE)

include(FetchContent)
FetchContent_Declare(juce
    GIT_REPOSITORY https://github.com/juce-framework/JUCE.git
    GIT_TAG juce-8.0.0)
FetchContent_MakeAvailable(juce)

set(SOURCES
    Source/PluginProcessor.cpp
    Source/PluginEditor.cpp)

function(add_xac_plugin target displayName code)
    juce_add_plugin(${target}
        COMPANY_NAME "XAC"
        BUNDLE_ID "audio.xac.${code}"
        PLUGIN_MANUFACTURER_CODE "XACx"
        PLUGIN_CODE "${code}"
        FORMATS VST3
        PRODUCT_NAME "${displayName}"
        IS_SYNTH FALSE
        NEEDS_MIDI_INPUT FALSE
        NEEDS_MIDI_OUTPUT FALSE
        IS_MIDI_EFFECT FALSE
        COPY_PLUGIN_AFTER_BUILD FALSE)
    target_sources(${target} PRIVATE ${SOURCES})
    target_compile_definitions(${target} PRIVATE JUCE_VST3_CAN_REPLACE_VST2=0)
    target_link_libraries(${target} PRIVATE
        juce::juce_audio_plugin_client
        juce::juce_audio_processors
        juce::juce_audio_utils
        juce::juce_dsp
        juce::juce_gui_basics
        juce::juce_gui_extra)
endfunction()

add_xac_plugin(XAClive "XAClive" "Xlv1")
add_xac_plugin(XACmusic "XACmusic" "Xmu1")