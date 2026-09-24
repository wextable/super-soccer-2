import Foundation

/// The previous app's shared joke-name list, copied in order, duplicates included.
/// First names, surnames, and the rare suffix use the same rolls as `NameFactory`.
enum NameGenerator {
    static let names: [String] = [
        "Bo", "Billy", "King", "Prince", "Major", "Xavier", "Lorenzo", "Buckwalter",
        "Raul", "Domingo", "Pepe", "Walter", "Wellington", "Ezekiel", "Ricardo", "Rapier",
        "Tank", "Thatcher", "Yimi", "Uncle", "Ignacio", "Orion", "Popeye", "Aaron",
        "Alastair", "Angelo", "Axilla", "Sammy", "Sperlock", "Sylvester", "DeAngelo", "Dirk",
        "Devonshire", "Diego", "Fergie", "Frankie", "Fillipe", "Ferdinand", "Foo", "Garbanzo",
        "Gregory", "George", "Guiseppe", "Gunter", "Hans", "Hampton", "Halicarnassas", "Hank",
        "Jackington", "Jaque", "Junior", "Jalopy", "Jeeves", "Johnson", "Javier", "Jose",
        "Jeremiah", "Killer", "Krypton", "Kelvin", "Keyonte", "Keyes", "Laquanza", "Legend",
        "Louis", "Leopold", "Larry", "La Garganta", "Maurice", "Monrovia", "Money", "Miguel",
        "Manzana", "Ned", "Nightingale", "Nikolaus", "Bronte", "Brigand", "Balzak", "Brian",
        "Bronson", "Benito", "Baldwin", "Victor", "Vanzetti", "Vince", "Carlos", "Conrad",
        "Crusty", "Chuckie", "Charleston", "Chesterfield", "Chadwick", "Chrissy", "Carmelo", "Zachary",
        "Zilgram", "Oden", "Bernard", "Willie", "Nelson", "Ajax", "Merlin", "Thor",
        "Bruce", "Bjorn", "Colt", "Donovan", "Enzo", "Logan", "Thomas", "Huxley",
        "St. James", "Lopez", "Ford", "Anderson", "Hendrix", "Katz", "Remington", "Cyprus",
        "Alexander", "Dios", "Alexus", "Armstrong", "Borstov", "Bushido", "Drakos", "Everhart",
        "Genji", "Halifax", "Hightower", "Jagger", "Molotov", "Nash", "Petrovski", "Underwood",
        "David", "Wesley", "St. John", "Marcus", "Thompson", "Kim", "Moon", "Lee",
        "Smith", "Walker", "Johan", "Antonio", "Tony", "Terrence", "Welch", "Steven",
        "Michael", "Adelberto", "Roberto", "Marlin", "Andrew", "Sandor", "Frazier", "Carl",
        "Benson", "Gutty", "Mitchel", "Magnusson", "Van Dyke", "Paulo", "Santa Cruz", "Jesus",
        "Emiliano", "Firenze", "Todd", "McDougal", "McCraley", "Newman", "Caesar", "Adam",
        "Jeremy", "Jamie", "Phillips", "Conner", "Jason", "Igloo", "Crank", "Berner",
        "Stetson", "Chicago", "Phoenix", "San Francisco", "Guy", "Roach", "Boy", "Vanillo",
        "Fedora", "Bennet", "Bigsby", "Wormsloe", "Pickle", "Chappy", "Smoke", "Davis",
        "Tique", "Vernon", "Reverand", "Pastor", "Mario", "Luigi", "Guillermo", "Scaramucci",
        "Babatunde", "Mamadou", "Forest", "Wolfgang", "Babacar", "Hoffmeier", "Ibrahim", "Malachi",
        "Monk", "Bozole", "Harrington", "Escobar", "Angel", "Gruyere", "Fabian", "Fabio",
        "Mbala", "Ruben", "Xavi", "Sung-Ho", "Yung-Soo", "Joon-Woo", "François", "Charles",
        "Henri", "Sébastien", "Gabriel", "Jules", "Mohamed", "Mustafa", "Shahid", "Jamal",
        "Shariffe", "Zameer", "Aladdin", "Kareem", "Saladin", "Xerxes", "Augustus", "Montezuma",
        "Washington", "Jefferson", "Madison", "Pablo", "Chomsky", "Vladimir", "Rohan", "Akash",
        "Shashant", "Benjamin", "Frivolity", "Shadrack", "Leviticus", "Danny", "Bobby", "Bob",
        "Jack", "Wesley", "Lane", "Dave", "Christopher", "Chris", "John", "Mike",
        "Lonnie", "Dick", "Andy", "Eric", "Frank", "Greg", "Gary", "Tennessee",
        "Chode", "Pico", "Harry", "Henry", "Klamath", "Hood", "Puerto Rico", "Sanchez",
        "Wall", "Zapato", "Orky", "Zarate", "Hannibal", "Rex", "Pistacio", "Justinian",
        "Kevin", "Phillips", "Strings", "Earnest", "Dusty", "Wyatt", "Hatfield", "McCoy",
        "Jimmy", "Melvin", "Precious", "Leon", "Cooper", "Fisher", "Tanner", "Finnigan",
        "Allday", "Donkey", "Marvin", "Morgan", "Dwane", "Matthew", "Mark", "Abednego",
        "Stag", "Ross", "Rock", "Gus", "Bruce", "Pearl", "Newton", "Slappy",
        "Happy", "Asthma", "Pedro", "Pezhmon", "Dwight", "Nathaniel", "Red", "Oscar",
        "Oliver", "Burns", "Nixon", "Patrick", "Irving", "Quincy", "DeLancy", "Randy",
        "Ricky", "Richie", "Robbie", "Ohio", "Florida", "Sam", "Texas", "Tyrone",
        "Valencia", "Valentino", "Rudolph", "Grant", "Bert", "Ernie", "Grover", "Murphy",
        "Wildman", "Wimpy", "West", "Webster", "Garcia", "Clementine", "Carthage", "Curtis",
        "Ish", "Isaac", "Icarus", "Ishmail", "Isreal", "Idaho", "Kenny", "Knight",
        "Norman", "Neil", "O'neil", "Uche", "Nexus", "Love", "Otis", "OshKosh",
        "Quinn", "Queef", "Quartz", "Queen", "Undertow", "Ulysses", "Udon", "Udder",
        "Ulrich", "Vargas", "Utah", "Yellow", "Yancy", "Zenith", "Polio", "Bunny",
        "Ellsworth", "Elijah", "Salvador", "Emerson", "Neckbeard", "Cadillac", "Brody", "Spencer",
        "Kenneth", "Engelbert", "Rod", "Gonzales", "Alberto", "Pierre", "Billiam", "Chestnutt",
        "Hammersmith", "Choctaw", "Cratchett", "Lance", "Lancelot", "Grub", "Strawberry", "Huckleberry",
        "Chorizo", "Stiffy", "Craig", "Michelangelo", "Leonardo", "João", "Gilbert", "Darrius",
        "Mister", "Freddie", "Mercury", "McDaniel", "Allah", "James", "Rodriguez", "Karl",
        "Stevenson", "Sven", "Bernardo", "Vespucci", "Chonker", "Guantanamo", "Jed", "Ping",
        "Orlando"
    ]

    static let suffixes: [String] = ["Sr.", "Jr.", "III", "IV"]

    static func makeFirstName(using generator: inout some RandomNumberGenerator) -> String {
        guard Int.random(in: 1...100, using: &generator) < 99 else { return "" }
        return names.randomElement(using: &generator)!
    }

    static func makeLastName(using generator: inout some RandomNumberGenerator) -> String {
        var lastName = names.randomElement(using: &generator)!
        if Int.random(in: 1...100, using: &generator) >= 99 {
            lastName += " " + makeSuffix(using: &generator)
        }
        return lastName
    }

    private static func makeSuffix(using generator: inout some RandomNumberGenerator) -> String {
        suffixes.randomElement(using: &generator)!
    }
}
