
import SwiftUI

struct ContentView: View {
    @StateObject var jokeViewModel: JokeApiViewModel = JokeApiViewModel()
    
    var body: some View {
        Text("Joke: \(jokeViewModel.joke)")
            .padding()
        
        Button("通信") {
            jokeViewModel.fetchJoke()
        }
    }
}

#Preview {
    ContentView()
}
