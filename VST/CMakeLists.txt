cmake_minimum_required(VERSION 3.22)
project(XACVST VERSION 1.0.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(FetchContent)
FetchContent_Declare(juce
    GIT_REPOSITORY https://github.com/juce-framework/JUCE.git
    GIT_TAG 8.0.14)
FetchContent_MakeAvailable(juce)

set(SOURCES
    Source/PluginProcessor.cpp
    Source/PluginEditor.cpp)

function(add_xac_plugin target displayName)
    juce_add_plugin(${target}
        COMPANY_NAME "XAC"
        BUNDLE_ID "audio.xac.${target}"
        PLUGIN_MANUFACTURER_CODE "XACx"
        PLUGIN_CODE "${target}"
        FORMATS VST3
        PRODUCT_NAME "${displayName}"
        IS_SYNTH FALSE
        NEEDS_MIDI_INPUT FALSE
        NEEDS_MIDI_OUTPUT FALSE
        IS_MIDI_EFFECT FALSE
        COPY_PLUGIN_AFTER_BUILD FALSE
        NEEDS_WEB_BROWSER FALSE
        NEEDS_CURL FALSE)
    target_sources(${target} PRIVATE ${SOURCES})
    target_compile_definitions(${target}
        PUBLIC
            JUCE_VST3_CAN_REPLACE_VST2=0
            JUCE_WEB_BROWSER=0
            JUCE_USE_CURL=0)
    target_link_libraries(${target}
        PUBLIC
            juce::juce_recommended_config_flags
            juce::juce_recommended_lto_flags
            juce::juce_recommended_warning_flags)
endfunction()

add_xac_plugin(XAClive "XAClive")
add_xac_plugin(XACmusic "XACmusic")