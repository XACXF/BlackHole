cmake_minimum_required(VERSION 3.22)
project(XACVST VERSION 1.0.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(FetchContent)
FetchContent_Declare(juce
    GIT_REPOSITORY https://github.com/juce-framework/JUCE.git
    GIT_TAG 8.0.14)
FetchContent_MakeAvailable(juce)

juce_add_plugin(XAClive
    COMPANY_NAME "XAC"
    BUNDLE_ID "audio.xac.XAClive"
    PLUGIN_MANUFACTURER_CODE "XACx"
    PLUGIN_CODE "Xlv1"
    FORMATS VST3 AU
    PRODUCT_NAME "XAC live"
    IS_SYNTH FALSE
    NEEDS_MIDI_INPUT FALSE
    NEEDS_MIDI_OUTPUT FALSE
    IS_MIDI_EFFECT FALSE
    COPY_PLUGIN_AFTER_BUILD FALSE
    NEEDS_WEB_BROWSER FALSE
    NEEDS_CURL FALSE)

target_sources(XAClive PRIVATE
    Source/PluginProcessor.cpp
    Source/PluginEditor.cpp)

target_compile_definitions(XAClive PRIVATE
    JUCE_VST3_CAN_REPLACE_VST2=0
    JUCE_WEB_BROWSER=0
    JUCE_USE_CURL=0)

juce_add_plugin(XACmusic
    COMPANY_NAME "XAC"
    BUNDLE_ID "audio.xac.XACmusic"
    PLUGIN_MANUFACTURER_CODE "XACx"
    PLUGIN_CODE "Xmu1"
    FORMATS VST3 AU
    PRODUCT_NAME "XAC music"
    IS_SYNTH FALSE
    NEEDS_MIDI_INPUT FALSE
    NEEDS_MIDI_OUTPUT FALSE
    IS_MIDI_EFFECT FALSE
    COPY_PLUGIN_AFTER_BUILD FALSE
    NEEDS_WEB_BROWSER FALSE
    NEEDS_CURL FALSE)

target_sources(XACmusic PRIVATE
    Source/PluginProcessor.cpp
    Source/PluginEditor.cpp)

target_compile_definitions(XACmusic PRIVATE
    JUCE_VST3_CAN_REPLACE_VST2=0
    JUCE_WEB_BROWSER=0
    JUCE_USE_CURL=0)
