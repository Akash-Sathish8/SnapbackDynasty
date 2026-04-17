import Foundation

/// Box-Muller transform: returns a normally distributed random value.
func gaussRandom(mean: Double, std: Double) -> Double {
    let u1 = Double.random(in: 0.001...1)
    let u2 = Double.random(in: 0.001...1)
    return mean + std * sqrt(-2 * log(u1)) * cos(2 * .pi * u2)
}
