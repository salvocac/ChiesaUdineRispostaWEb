import SwiftUI

struct VerseCardView: View {

    let reference: String
    let verse: String

    var body: some View {

        ZStack {

            LinearGradient(
                colors: [
                    Color.blue.opacity(0.95),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {

                Spacer()

                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120)

                Text(reference)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)

                Text("“\(verse)”")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.horizontal, 60)

                Spacer()

                VStack(spacing: 6) {

                    Text("Chiesa Cristiana Evangelica")
                        .font(.headline)

                    Text("Friulana di Udine")
                        .font(.headline)
                }
                .foregroundColor(.white.opacity(0.9))

                Text("www.chiesacristianaudine.it")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(50)
        }
        .frame(width: 1080, height: 1350)
    }
}

#Preview {
    VerseCardView(
        reference: "Giovanni 3:16",
        verse: "Poiché Dio ha tanto amato il mondo che ha dato il suo unigenito Figlio."
    )
}
