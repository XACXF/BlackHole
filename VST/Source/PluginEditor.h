#pragma once
#include <juce_gui_basics/juce_gui_basics.h>
#include "PluginProcessor.h"

class XACAudioEditor : public juce::AudioProcessorEditor, public juce::Timer
{
public:
    XACAudioEditor(XACAudioProcessor&);
    ~XACAudioEditor() override;

    void paint(juce::Graphics&) override;
    void resized() override;
    void timerCallback() override;

private:
    XACAudioProcessor& processor;
    juce::Slider inputGain, outputLevel;
    juce::ToggleButton phase, bypass;
    juce::Label inMeterLabel, outMeterLabel;
    juce::AudioProcessorValueTreeState::SliderAttachment inputGainAttach, outputLevelAttach;
    juce::AudioProcessorValueTreeState::ButtonAttachment phaseAttach, bypassAttach;
    float inMeter = 0.0f, outMeter = 0.0f;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(XACAudioEditor)
};