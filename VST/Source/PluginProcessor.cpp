#include "PluginProcessor.h"
#include "PluginEditor.h"
#include <cmath>

XACAudioProcessor::XACAudioProcessor()
    : AudioProcessor(BusesProperties()
          .withInput("Input", juce::AudioChannelSet::stereo(), true)
          .withOutput("Output", juce::AudioChannelSet::stereo(), true)),
      parameters(*this, nullptr, juce::Identifier("XACBridge"),
          { std::make_unique<juce::AudioParameterFloat>(juce::ParameterID("inputGain", 1), "Input Gain", -60.0f, 12.0f, 0.0f),
            std::make_unique<juce::AudioParameterFloat>(juce::ParameterID("outputLevel", 2), "Output Level", -60.0f, 0.0f, 0.0f),
            std::make_unique<juce::AudioParameterBool>(juce::ParameterID("phase", 3), "Phase Invert", false),
            std::make_unique<juce::AudioParameterBool>(juce::ParameterID("bypass", 4), "Bypass", false) })
{
}

XACAudioProcessor::~XACAudioProcessor() {}

bool XACAudioProcessor::isBusesLayoutSupported(const BusesLayout& layouts) const
{
    if (layouts.getMainOutputChannels() == 0) return false;
    if (layouts.getMainOutputChannels() != layouts.getMainInputChannels()) return false;
    return true;
}

void XACAudioProcessor::prepareToPlay(double, int) {}
void XACAudioProcessor::releaseResources() {}

void XACAudioProcessor::processBlock(juce::AudioBuffer<float>& buffer, juce::MidiBuffer&)
{
    auto* ig = parameters.getRawParameterValue("inputGain");
    auto* ol = parameters.getRawParameterValue("outputLevel");
    auto* ph = parameters.getRawParameterValue("phase");
    auto* bp = parameters.getRawParameterValue("bypass");

    const float gain = juce::Decibels::decibelsToGain(ig->load());
    const float lvl = juce::Decibels::decibelsToGain(ol->load());
    const bool phase = ph->load() > 0.5f;
    const bool bypass = bp->load() > 0.5f;

    const int numOut = getTotalNumOutputChannels();
    const int numIn = getTotalNumInputChannels();
    float inPeak = 0.0f, outPeak = 0.0f;

    for (int ch = 0; ch < numOut; ++ch)
    {
        auto* out = buffer.getWritePointer(ch);
        auto* in = buffer.getReadPointer(jmin(ch, numIn - 1));
        for (int s = 0; s < buffer.getNumSamples(); ++s)
        {
            float x = in[s];
            float y = bypass ? x : (phase ? -x * gain : x * gain) * lvl;
            out[s] = y;
            inPeak = jmax(inPeak, std::abs(x));
            outPeak = jmax(outPeak, std::abs(y));
        }
    }
    inputMeter.store(inPeak);
    outputMeter.store(outPeak);
}

juce::AudioProcessorEditor* XACAudioProcessor::createEditor()
{
    return new XACAudioEditor(*this);
}

void XACAudioProcessor::getStateInformation(juce::MemoryBlock& dest)
{
    auto state = parameters.copyState();
    juce::MemoryOutputStream os(dest, false);
    state.writeToStream(os);
}

void XACAudioProcessor::setStateInformation(const void* data, int sizeInBytes)
{
    auto state = juce::ValueTree::readFromData(data, (size_t)sizeInBytes);
    if (state.isValid())
        parameters.replaceState(state);
}