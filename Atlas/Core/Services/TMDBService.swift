import Foundation

// MARK: - TMDB API Models
struct TMDBResponse: Codable, Sendable {
    let results: [TMDBItem]
}

struct TMDBItem: Codable, Sendable {
    let id: Int
    let title: String?
    let name: String?
    let posterPath: String?
    let backdropPath: String?
    let overview: String?
    let releaseDate: String?
    let firstAirDate: String?
    let voteAverage: Double?
    let genreIds: [Int]?
    let mediaType: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, name, overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case voteAverage = "vote_average"
        case genreIds = "genre_ids"
        case mediaType = "media_type"
    }
    
    var displayTitle: String {
        return title ?? name ?? "Unknown Title"
    }
    
    var releaseYear: String? {
        let dateString = releaseDate ?? firstAirDate
        return dateString?.prefix(4).description
    }
    
    var posterURL: String? {
        guard let posterPath = posterPath else { return nil }
        return "https://image.tmdb.org/t/p/w500\(posterPath)"
    }
    
    var backdropURL: String? {
        guard let backdropPath = backdropPath else { return nil }
        return "https://image.tmdb.org/t/p/w1280\(backdropPath)"
    }
}

struct TMDBGenre: Codable, Sendable {
    let id: Int
    let name: String
}

struct TMDBGenresResponse: Codable, Sendable {
    let genres: [TMDBGenre]
}

// MARK: - TMDB Service
typealias TMDBItemsHandler = @Sendable ([TMDBItem]) -> Void

@MainActor
class TMDBService: ObservableObject {
    private let apiKey = "ef7b7742bbbbbd9313975f57b4a00d49"
    private let baseURL = "https://api.themoviedb.org/3"
    private let imageBaseURL = "https://image.tmdb.org/t/p"
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var genreCache: [Int: String] = [:]
    
    init() {
        loadGenres()
    }
    
    // MARK: - Search Methods
    func searchMovies(query: String) async -> [TMDBItem] {
        await searchContent(query: query, type: "movie")
    }
    
    func searchTVShows(query: String) async -> [TMDBItem] {
        await searchContent(query: query, type: "tv")
    }
    
    func searchAll(query: String) async -> [TMDBItem] {
        await searchContent(query: query, type: "multi")
    }
    
    private func searchContent(query: String, type: String) async -> [TMDBItem] {
        guard !query.isEmpty else { return [] }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)/search/\(type)?api_key=\(apiKey)&query=\(encodedQuery)&include_adult=false"
        
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            return []
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(TMDBResponse.self, from: data)
            return response.results
        } catch {
            errorMessage = "Failed to search: \(error.localizedDescription)"
            return []
        }
    }
    
    // MARK: - Genre Loading
    private func loadGenres() {
        // Load genres synchronously for now to avoid Task naming conflict
        loadMovieGenresSync()
        loadTVGenresSync()
    }
    
    private func loadMovieGenres() async {
        let urlString = "\(baseURL)/genre/movie/list?api_key=\(apiKey)"
        
        guard let url = URL(string: urlString) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(TMDBGenresResponse.self, from: data)
            
            for genre in response.genres {
                genreCache[genre.id] = genre.name
            }
        } catch {
            print("Failed to load movie genres: \(error)")
        }
    }
    
    private func loadTVGenres() async {
        let urlString = "\(baseURL)/genre/tv/list?api_key=\(apiKey)"
        
        guard let url = URL(string: urlString) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(TMDBGenresResponse.self, from: data)
            
            for genre in response.genres {
                genreCache[genre.id] = genre.name
            }
        } catch {
            print("Failed to load TV genres: \(error)")
        }
    }
    
    func getGenreName(for id: Int) -> String {
        return genreCache[id] ?? "Unknown Genre"
    }
    
    func getGenreNames(for ids: [Int]) -> [String] {
        return ids.compactMap { genreCache[$0] }
    }
    
    // MARK: - Completion Handler Versions
    func searchMovies(query: String, completion: @escaping TMDBItemsHandler) {
        print("🔍 Searching for movies with query: '\(query)'")
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/search/movie?api_key=\(apiKey)&query=\(encodedQuery)") else {
            print("❌ Failed to create URL for movie search")
            completion([])
            return
        }
        
        print("🌐 Making request to: \(url)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Error searching movies: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            
            print("✅ Received \(data.count) bytes of data")
            
            do {
                let response = try JSONDecoder().decode(TMDBResponse.self, from: data)
                print("✅ Found \(response.results.count) movie results")
                DispatchQueue.main.async {
                    completion(response.results)
                }
            } catch {
                print("❌ Error decoding movie search results: \(error)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }.resume()
    }
    
    func searchTVShows(query: String, completion: @escaping TMDBItemsHandler) {
        print("🔍 Searching for TV shows with query: '\(query)'")
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/search/tv?api_key=\(apiKey)&query=\(encodedQuery)") else {
            print("❌ Failed to create URL for TV show search")
            completion([])
            return
        }
        
        print("🌐 Making request to: \(url)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Error searching TV shows: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            
            print("✅ Received \(data.count) bytes of data")
            
            do {
                let response = try JSONDecoder().decode(TMDBResponse.self, from: data)
                print("✅ Found \(response.results.count) TV show results")
                DispatchQueue.main.async {
                    completion(response.results)
                }
            } catch {
                print("❌ Error decoding TV search results: \(error)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }.resume()
    }
    
    func searchAll(query: String, completion: @escaping TMDBItemsHandler) {
        print("🔍 Searching for all content (movies + TV shows) with query: '\(query)'")
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/search/multi?api_key=\(apiKey)&query=\(encodedQuery)") else {
            print("❌ Failed to create URL for multi search")
            completion([])
            return
        }
        
        print("🌐 Making request to: \(url)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Error searching all content: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            
            guard let data = data else {
                print("❌ No data received for multi search")
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            
            do {
                let response = try JSONDecoder().decode(TMDBResponse.self, from: data)
                print("✅ Successfully decoded \(response.results.count) total results")
                DispatchQueue.main.async {
                    completion(response.results)
                }
            } catch {
                print("❌ Error decoding multi search results: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📄 Raw JSON response: \(jsonString)")
                }
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }.resume()
    }
    
    private func loadMovieGenresSync() {
        let urlString = "\(baseURL)/genre/movie/list?api_key=\(apiKey)"
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                print("Error loading movie genres: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                let genreResponse = try JSONDecoder().decode(TMDBGenresResponse.self, from: data)
                DispatchQueue.main.async {
                    for genre in genreResponse.genres {
                        self?.genreCache[genre.id] = genre.name
                    }
                }
            } catch {
                print("Error decoding movie genres: \(error)")
            }
        }.resume()
    }
    
    private func loadTVGenresSync() {
        let urlString = "\(baseURL)/genre/tv/list?api_key=\(apiKey)"
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                print("Error loading TV genres: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                let genreResponse = try JSONDecoder().decode(TMDBGenresResponse.self, from: data)
                DispatchQueue.main.async {
                    for genre in genreResponse.genres {
                        self?.genreCache[genre.id] = genre.name
                    }
                }
            } catch {
                print("Error decoding TV genres: \(error)")
            }
        }.resume()
    }
}
