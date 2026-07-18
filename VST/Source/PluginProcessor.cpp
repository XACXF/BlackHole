#include "PluginProcessor.h"
#include "PluginEditor.h"
#include <cmath>

XACAudioProcessor::XACAudioProcessor()
    : AudioProcessor(BusesProperties()
          .withInput("Input", juce::AudioChannelSet::stereo(), true)
          .withOutput("Output", juce::AudioChannelSet::stereo(), true)),
      parameters(*this, nullptr, "XACBridge",
          { std::make_unique<juce::AudioParameterFloat>("inputGain", "Input Gain", -60.0f, 12.0f, 0.0f),
            std::make_unique<juce::AudioParameterFloat>("outputLevel", "Output Level", -60.0f, 0.0f, 0.0f),
            std::make_unique<juce::AudioParameterBool>("phase", "Phase Invert", false),
            std::make_unique<juce::AudioParameterBool>("bypass", "Bypass", false) })
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
        auto* in = buffer.getReadPointer((numIn > 0) ? ch : 0);
        for (int s = 0; s < buffer.getNumSamples(); ++s)
        {
            float x = in[s];
            float y = bypass ? x : (phase ? -x * gain : x * gain) * lvl;
            out[s] = y;
            inPeak = std::fmax(inPeak, std::abs(x));
            outPeak = std::fmax(outPeak, std::abs(y));
        }
    }
    inputMeter.store(inPeak, std::memory_order_relaxed);
    outputMeter.store(outPeak, std::memory_order_relaxed);
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

// JUCE VST3 entry point (required by juce_add_plugin)
juce::AudioProcessor* JUCE_CALLTYPE createPluginFilter()
{
    return new XACAudioProcessor();
}
