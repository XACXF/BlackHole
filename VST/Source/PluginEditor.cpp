#include "PluginEditor.h"

XACAudioEditor::XACAudioEditor(XACAudioProcessor& p)
    : AudioProcessorEditor(p), processor(p),
      inputGainAttach(p.parameters, juce::ParameterID("inputGain", 1), inputGain),
      outputLevelAttach(p.parameters, juce::ParameterID("outputLevel", 2), outputLevel),
      phaseAttach(p.parameters, juce::ParameterID("phase", 3), phase),
      bypassAttach(p.parameters, juce::ParameterID("bypass", 4), bypass)
{
    setSize(360, 240);

    inputGain.setSliderStyle(juce::Slider::LinearHorizontal);
    outputLevel.setSliderStyle(juce::Slider::LinearHorizontal);
    inputGain.setTextValueSuffix(" dB");
    outputLevel.setTextValueSuffix(" dB");
    addAndMakeVisible(inputGain);
    addAndMakeVisible(outputLevel);

    phase.setButtonText("Phase Invert");
    bypass.setButtonText("Bypass (dry)");
    addAndMakeVisible(phase);
    addAndMakeVisible(bypass);

    addAndMakeVisible(inMeterLabel);
    addAndMakeVisible(outMeterLabel);

    startTimerHz(30);
}

XACAudioEditor::~XACAudioEditor()
{
    stopTimer();
}

void XACAudioEditor::resized()
{
    int y = 16;
    inputGain.setBounds(16, y, getWidth() - 32, 30); y += 44;
    outputLevel.setBounds(16, y, getWidth() - 32, 30); y += 48;
    phase.setBounds(16, y, 160, 30);
    bypass.setBounds(190, y, 150, 30); y += 48;
    inMeterLabel.setBounds(16, y, 160, 22);
    outMeterLabel.setBounds(190, y, 160, 22);
}

void XACAudioEditor::timerCallback()
{
    inMeter = processor.getInputMeter();
    outMeter = processor.getOutputMeter();
    inMeterLabel.setText("In: " + juce::String(juce::Decibels::gainToDecibels(inMeter, -60.0f), 1) + " dB", juce::dontSendNotification);
    outMeterLabel.setText("Out: " + juce::String(juce::Decibels::gainToDecibels(outMeter, -60.0f), 1) + " dB", juce::dontSendNotification);
}

void XACAudioEditor::paint(juce::Graphics& g)
{
    g.fillAll(juce::Colours::darkgrey.darker());
}
// BUILD: 1784335904.3654754
