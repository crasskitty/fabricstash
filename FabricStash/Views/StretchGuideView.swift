import SwiftUI

struct StretchGuideView: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: (StretchTestResult) -> Void

    @State private var step = 0
    @State private var crosswiseText = ""
    @State private var lengthwiseText = ""
    @State private var crosswiseRecovery: Recovery = .untested
    @State private var lengthwiseRecovery: Recovery = .untested

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Step \(step + 1) of 6")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Studio.madder)
                    stepContent
                }
                .padding(20)
            }
            .studioScreen()
            .navigationTitle("Stretch test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 0:
            intro
        case 1:
            measure(
                title: "Crosswise",
                body: "Mark 10 cm from selvedge toward selvedge, across the cloth. Hold one end of the mark and pull the other until the fabric resists and you would not want to pull harder. Measure the mark again and type that length.",
                text: $crosswiseText
            )
        case 2:
            recoveryStep(
                title: "Did it spring back?",
                body: "Let go. If the mark returns close to 10 cm, recovery is good. If it stays long, wavy, or baggy, recovery is poor.",
                selection: $crosswiseRecovery
            )
        case 3:
            measure(
                title: "Lengthwise",
                body: "Mark a fresh 10 cm parallel to the selvedge, along the length of the cloth. Pull until it resists, then measure the mark again.",
                text: $lengthwiseText
            )
        case 4:
            recoveryStep(
                title: "Lengthwise recovery",
                body: "Let go again. Judge this direction on its own.",
                selection: $lengthwiseRecovery
            )
        default:
            summary
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("A tape-measure test")
                .font(Studio.serif(.title, weight: .semibold))
                .foregroundStyle(Studio.ink)
            Text("\(AppIdentity.displayName) does not use the phone’s sensors to measure stretch. You mark the cloth, pull it by hand, read a tape, and type what you see.")
                .foregroundStyle(Studio.ink)
            Text("Ten centimeters is the mark because the math is easy: if 10 cm becomes 13 cm, that is 30% stretch.")
                .foregroundStyle(Studio.ink)
            Text("You will do it twice. First across the fabric (crosswise), then along it (lengthwise). After both, you can save 2-way, 4-way, or no stretch.")
                .foregroundStyle(Studio.ink)
            Button("Start with the crosswise mark") { step = 1 }
                .buttonStyle(MadderButtonStyle())
        }
    }

    private func measure(title: String, body: String, text: Binding<String>) -> some View {
        let percent = NumberParsing.double(from: text.wrappedValue).flatMap {
            StretchAssessment.percent(stretchedCentimeters: $0)
        }
        return VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(Studio.serif(.title, weight: .semibold))
                .foregroundStyle(Studio.ink)
            Text(body)
                .foregroundStyle(Studio.ink)
            Text("The phone is only holding the number. It is not measuring the cloth.")
                .font(.subheadline)
                .foregroundStyle(Studio.inkSecondary)
            TextField("Stretched mark in cm", text: text)
                .keyboardType(.decimalPad)
                .padding(12)
                .background(Studio.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityLabel("Stretched mark in centimeters")
            if text.wrappedValue.trimmingCharacters(in: .whitespaces).isEmpty {
                Text("The relaxed mark was \(NumberParsing.string(StretchAssessment.markedCentimeters, fractionDigits: 0)) cm.")
                    .foregroundStyle(Studio.inkSecondary)
            } else if let percent {
                Text("That is \(NumberParsing.string(percent))% stretch.")
                    .font(.headline)
                    .foregroundStyle(Studio.ink)
            } else {
                Text("That is shorter than 10 cm. Type the length of the mark while it is stretched, not the relaxed length.")
                    .foregroundStyle(Studio.madder)
            }
            HStack {
                Button("Back") { step -= 1 }
                    .buttonStyle(.bordered)
                Button("Next") { step += 1 }
                    .buttonStyle(MadderButtonStyle())
                    .disabled(percent == nil)
            }
        }
    }

    private func recoveryStep(title: String, body: String, selection: Binding<Recovery>) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(Studio.serif(.title, weight: .semibold))
                .foregroundStyle(Studio.ink)
            Text(body)
                .foregroundStyle(Studio.ink)
            Button("Good — it sprang back") { selection.wrappedValue = .good }
                .buttonStyle(selection.wrappedValue == .good ? MadderButtonStyle() : GreenButtonStyle())
            Button("Poor — it stayed stretched") { selection.wrappedValue = .poor }
                .buttonStyle(selection.wrappedValue == .poor ? MadderButtonStyle() : GreenButtonStyle())
            HStack {
                Button("Back") { step -= 1 }
                    .buttonStyle(.bordered)
                Button("Next") { step += 1 }
                    .buttonStyle(MadderButtonStyle())
                    .disabled(selection.wrappedValue == .untested)
            }
        }
    }

    private var summary: some View {
        let crosswise = NumberParsing.double(from: crosswiseText).flatMap {
            StretchAssessment.percent(stretchedCentimeters: $0)
        } ?? 0
        let lengthwise = NumberParsing.double(from: lengthwiseText).flatMap {
            StretchAssessment.percent(stretchedCentimeters: $0)
        } ?? 0
        let result = StretchAssessment.result(
            crosswisePercent: crosswise,
            lengthwisePercent: lengthwise,
            crosswiseRecovery: crosswiseRecovery,
            lengthwiseRecovery: lengthwiseRecovery
        )
        return VStack(alignment: .leading, spacing: 14) {
            Text("What to save")
                .font(Studio.serif(.title, weight: .semibold))
                .foregroundStyle(Studio.ink)
            Text(StretchAssessment.explanation(for: result.kind, crosswise: crosswise, lengthwise: lengthwise))
                .foregroundStyle(Studio.ink)
            Text("Recovery: \(result.recovery.title). If either direction stayed stretched, the cloth is recorded as poor recovery.")
                .foregroundStyle(Studio.ink)
            Text("Suggested: \(result.kind.title). You can change it later in the fabric editor.")
                .foregroundStyle(Studio.inkSecondary)
            Button("Save on this fabric") {
                onSave(result)
                dismiss()
            }
            .buttonStyle(MadderButtonStyle())
            Button("Close without saving") { dismiss() }
                .frame(maxWidth: .infinity)
            Button("Back") { step -= 1 }
                .buttonStyle(.bordered)
        }
    }
}
