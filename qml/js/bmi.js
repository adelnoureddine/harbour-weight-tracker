.pragma library

/*
 * Body mass index for adults, as the WHO and the CDC classify it.
 *
 * The BMI is rounded to one decimal before it is classified, and that rounded value is
 * the one shown. Version 0.3 classified the unrounded value and showed two decimals:
 * 160 cm and 64 kg came out as 24.999999999999996 ("Normal weight"), and 151 cm and
 * 57 kg showed "25.00" next to "Normal weight".
 */

// Upper limits of the categories, in kg/m²: Underweight, Normal weight, Overweight,
// Obesity class I, II; class III has none.
var LIMITS = [18.5, 25, 30, 35, 40];

// The healthy range shown for a height, the WHO's 18.5 to 24.9 (one decimal, so it ends
// where "Normal weight" does).
var HEALTHY_MIN = 18.5;
var HEALTHY_MAX = 24.9;

// The span of the scale under the result.
var SCALE_MIN = 15;
var SCALE_MAX = 40;

function round1(value) {
    return Math.round(value * 10) / 10;
}

// The BMI for a height in centimetres and a weight in kilograms, to one decimal; null
// without both.
function compute(heightCm, weightKg) {
    if (!(heightCm > 0) || !(weightKg > 0)) {
        return null;
    }
    // In whole units first: kg * 10000 / cm² keeps 64 / 1.6² from coming out a hair
    // under 25.
    return round1(weightKg * 10000 / (heightCm * heightCm));
}

// 0 Underweight, 1 Normal weight, 2 Overweight, 3-5 Obesity class I-III; -1 without a BMI.
function category(bmi) {
    if (bmi === null || bmi === undefined || isNaN(bmi)) {
        return -1;
    }
    for (var i = 0; i < LIMITS.length; i++) {
        if (bmi < LIMITS[i]) {
            return i;
        }
    }
    return LIMITS.length;
}

// The colour of a category, as Health draws its BMI bands.
function categoryColor(index) {
    switch (index) {
    case 0:  return "#3498db";  // blue
    case 1:  return "#2ecc71";  // green
    case 2:  return "#e67e22";  // orange
    case -1: return "transparent";
    default: return "#e74c3c";  // red
    }
}

// {min, max} in kg, to one decimal, of the healthy weight for a height in centimetres.
function healthyRange(heightCm) {
    if (!(heightCm > 0)) {
        return null;
    }
    var square = heightCm * heightCm / 10000;
    return { min: round1(HEALTHY_MIN * square), max: round1(HEALTHY_MAX * square) };
}

// vim:et:ts=4:sw=4
