"""
Django management command to populate Math subject with:
- 12 modules covering Class 9 Math topics
- 6 chapters per module
- 10 questions per chapter
- 3 HOTS questions per chapter
"""

from django.core.management.base import BaseCommand
from django.db import transaction
from gyaan_buddy.subjects.models import (
    Subject, Module, ModuleChapter, ModuleContent, 
    Question, Option, ChapterHOTS
)
from gyaan_buddy.users.models import Account
import random

SUBJECT_NAME = 'Math'

MATH_MODULES = {
    'Number Systems': {
        'description': 'Study of real numbers, rational and irrational numbers, and their properties',
        'chapters': [
            {'title': 'Introduction to Number Systems', 'description': 'Overview of different types of numbers'},
            {'title': 'Rational Numbers', 'description': 'Properties and operations on rational numbers'},
            {'title': 'Irrational Numbers', 'description': 'Understanding irrational numbers and their properties'},
            {'title': 'Real Numbers and Decimal Expansions', 'description': 'Decimal representations of real numbers'},
            {'title': 'Laws of Exponents for Real Numbers', 'description': 'Exponent rules with real number bases'},
            {'title': 'Number Line and Operations', 'description': 'Representing and operating numbers on number line'},
        ]
    },
    'Polynomials': {
        'description': 'Study of polynomials, their zeros, and factorization',
        'chapters': [
            {'title': 'Introduction to Polynomials', 'description': 'Basic concepts and terminology of polynomials'},
            {'title': 'Zeros of a Polynomial', 'description': 'Finding and understanding zeros of polynomials'},
            {'title': 'Remainder Theorem', 'description': 'Application of remainder theorem'},
            {'title': 'Factor Theorem', 'description': 'Using factor theorem for factorization'},
            {'title': 'Factorization of Polynomials', 'description': 'Various methods of factoring polynomials'},
            {'title': 'Algebraic Identities', 'description': 'Standard algebraic identities and applications'},
        ]
    },
    'Coordinate Geometry': {
        'description': 'Study of geometry using coordinate system',
        'chapters': [
            {'title': 'Cartesian Coordinate System', 'description': 'Introduction to coordinate planes and axes'},
            {'title': 'Plotting Points', 'description': 'Locating and plotting points in coordinate plane'},
            {'title': 'Quadrants', 'description': 'Understanding the four quadrants'},
            {'title': 'Distance Formula', 'description': 'Calculating distance between two points'},
            {'title': 'Section Formula', 'description': 'Finding points dividing a line segment'},
            {'title': 'Area of Triangle', 'description': 'Computing area using coordinates'},
        ]
    },
    'Linear Equations in Two Variables': {
        'description': 'Study of linear equations and their graphical representation',
        'chapters': [
            {'title': 'Introduction to Linear Equations', 'description': 'Basic concepts of linear equations'},
            {'title': 'Solution of Linear Equation', 'description': 'Finding solutions of linear equations'},
            {'title': 'Graph of Linear Equation', 'description': 'Graphical representation of linear equations'},
            {'title': 'Equations of Lines Parallel to Axes', 'description': 'Special cases of linear equations'},
            {'title': 'Simultaneous Linear Equations', 'description': 'Systems of linear equations'},
            {'title': 'Word Problems', 'description': 'Real-world applications of linear equations'},
        ]
    },
    'Introduction to Euclid\'s Geometry': {
        'description': 'Fundamental concepts of Euclidean geometry',
        'chapters': [
            {'title': 'Euclid\'s Definitions', 'description': 'Basic definitions in Euclidean geometry'},
            {'title': 'Euclid\'s Axioms', 'description': 'Understanding Euclid\'s axioms'},
            {'title': 'Euclid\'s Postulates', 'description': 'The five postulates of Euclid'},
            {'title': 'Equivalent Versions of Fifth Postulate', 'description': 'Different forms of parallel postulate'},
            {'title': 'Theorems and Proofs', 'description': 'Basic geometric theorems'},
            {'title': 'Non-Euclidean Geometry Introduction', 'description': 'Brief overview of non-Euclidean geometry'},
        ]
    },
    'Lines and Angles': {
        'description': 'Study of lines, angles, and their properties',
        'chapters': [
            {'title': 'Basic Terms and Definitions', 'description': 'Points, lines, rays, and segments'},
            {'title': 'Types of Angles', 'description': 'Acute, right, obtuse, straight, reflex angles'},
            {'title': 'Pairs of Angles', 'description': 'Complementary, supplementary, adjacent angles'},
            {'title': 'Parallel Lines and Transversal', 'description': 'Properties of parallel lines cut by transversal'},
            {'title': 'Angle Sum Property', 'description': 'Angle relationships in triangles'},
            {'title': 'Exterior Angle Theorem', 'description': 'Properties of exterior angles'},
        ]
    },
    'Triangles': {
        'description': 'Properties and congruence of triangles',
        'chapters': [
            {'title': 'Types of Triangles', 'description': 'Classification by sides and angles'},
            {'title': 'Congruence of Triangles', 'description': 'Understanding congruent triangles'},
            {'title': 'Criteria for Congruence', 'description': 'SSS, SAS, ASA, AAS, RHS criteria'},
            {'title': 'Properties of Triangles', 'description': 'Important properties and theorems'},
            {'title': 'Inequalities in Triangles', 'description': 'Triangle inequality theorem'},
            {'title': 'Pythagoras Theorem', 'description': 'The Pythagorean theorem and applications'},
        ]
    },
    'Quadrilaterals': {
        'description': 'Study of four-sided polygons and their properties',
        'chapters': [
            {'title': 'Types of Quadrilaterals', 'description': 'Classification of quadrilaterals'},
            {'title': 'Properties of Parallelograms', 'description': 'Theorems on parallelograms'},
            {'title': 'Rectangles and Squares', 'description': 'Special parallelograms'},
            {'title': 'Rhombus and Trapezium', 'description': 'Properties of rhombus and trapezium'},
            {'title': 'Mid-Point Theorem', 'description': 'Mid-point theorem and its applications'},
            {'title': 'Angle Sum Property', 'description': 'Sum of angles in quadrilaterals'},
        ]
    },
    'Circles': {
        'description': 'Study of circles and their properties',
        'chapters': [
            {'title': 'Basic Terms Related to Circles', 'description': 'Radius, diameter, chord, arc, sector'},
            {'title': 'Angle Subtended by a Chord', 'description': 'Angles formed by chords'},
            {'title': 'Perpendicular from Centre to Chord', 'description': 'Properties of perpendicular bisector'},
            {'title': 'Cyclic Quadrilaterals', 'description': 'Quadrilaterals inscribed in circles'},
            {'title': 'Tangent to a Circle', 'description': 'Properties of tangent lines'},
            {'title': 'Theorems on Circles', 'description': 'Important circle theorems'},
        ]
    },
    'Heron\'s Formula': {
        'description': 'Calculating area of triangles using Heron\'s formula',
        'chapters': [
            {'title': 'Introduction to Heron\'s Formula', 'description': 'Derivation and understanding of the formula'},
            {'title': 'Area of Triangle', 'description': 'Calculating area using Heron\'s formula'},
            {'title': 'Semi-Perimeter', 'description': 'Understanding and calculating semi-perimeter'},
            {'title': 'Application to Scalene Triangles', 'description': 'Using formula for scalene triangles'},
            {'title': 'Area of Quadrilaterals', 'description': 'Dividing into triangles to find area'},
            {'title': 'Word Problems', 'description': 'Real-world applications of Heron\'s formula'},
        ]
    },
    'Surface Areas and Volumes': {
        'description': 'Mensuration of 3D shapes',
        'chapters': [
            {'title': 'Surface Area of Cuboid and Cube', 'description': 'Calculating surface area of cuboids'},
            {'title': 'Surface Area of Cylinder', 'description': 'Curved and total surface area of cylinders'},
            {'title': 'Surface Area of Cone and Sphere', 'description': 'Surface areas of cones and spheres'},
            {'title': 'Volume of Cuboid and Cube', 'description': 'Calculating volumes of cuboids'},
            {'title': 'Volume of Cylinder', 'description': 'Volume calculations for cylinders'},
            {'title': 'Volume of Cone and Sphere', 'description': 'Volumes of cones and spheres'},
        ]
    },
    'Statistics': {
        'description': 'Collection, organization, and interpretation of data',
        'chapters': [
            {'title': 'Collection of Data', 'description': 'Methods of data collection'},
            {'title': 'Presentation of Data', 'description': 'Organizing and presenting data'},
            {'title': 'Graphical Representation', 'description': 'Bar graphs, histograms, frequency polygons'},
            {'title': 'Measures of Central Tendency', 'description': 'Mean, median, mode'},
            {'title': 'Mean of Grouped Data', 'description': 'Calculating mean for grouped data'},
            {'title': 'Median and Mode of Grouped Data', 'description': 'Finding median and mode for grouped data'},
        ]
    },
}

QUESTION_TYPES = ['mcq_single', 'mcq_multiple', 'short_answer', 'rearrange']

def get_chapter_questions(module_name, chapter_title):
    """Generate 10 questions for a chapter based on module and chapter."""
    questions = []
    
    if module_name == 'Number Systems':
        if chapter_title == 'Introduction to Number Systems':
            questions = [
                {'q': 'Which of the following is a natural number?', 'opts': ['5', '-3', '0', '2.5'], 'correct': [0], 'exp': 'Natural numbers are positive integers starting from 1. 5 is a natural number.', 'type': 'mcq_single'},
                {'q': 'Zero belongs to which set of numbers?', 'opts': ['Whole numbers', 'Natural numbers', 'Negative integers', 'None'], 'correct': [0], 'exp': 'Zero is included in whole numbers but not in natural numbers.', 'type': 'mcq_single'},
                {'q': 'Which of the following are whole numbers? (Select all that apply)', 'opts': ['0', '5', '-3', '100'], 'correct': [0, 1, 3], 'exp': 'Whole numbers are 0, 1, 2, 3, ... They include 0, 5, and 100. Negative numbers are not whole numbers.', 'type': 'mcq_multiple'},
                {'q': 'Select all integers from the following:', 'opts': ['-5', '0', '3.5', '7'], 'correct': [0, 1, 3], 'exp': 'Integers include positive, negative numbers and zero. 3.5 is not an integer.', 'type': 'mcq_multiple'},
                {'q': 'What is the smallest natural number?', 'opts': [], 'correct': [], 'exp': 'The smallest natural number is 1. Natural numbers start from 1 and go to infinity.', 'type': 'short_answer', 'answer': '1'},
                {'q': 'How many whole numbers are there between 5 and 15 (not including 5 and 15)?', 'opts': [], 'correct': [], 'exp': 'Whole numbers between 5 and 15: 6,7,8,9,10,11,12,13,14 = 9 numbers', 'type': 'short_answer', 'answer': '9'},
                {'q': 'Arrange the following number sets from smallest to largest (subset to superset):', 'opts': ['Natural Numbers', 'Whole Numbers', 'Integers', 'Real Numbers'], 'correct': [0, 1, 2, 3], 'exp': 'Natural ⊂ Whole ⊂ Integers ⊂ Real Numbers', 'type': 'rearrange'},
                {'q': 'Arrange these numbers in ascending order:', 'opts': ['-5', '-2', '0', '3'], 'correct': [0, 1, 2, 3], 'exp': '-5 < -2 < 0 < 3', 'type': 'rearrange'},
                {'q': 'The predecessor of -10 is:', 'opts': ['-11', '-9', '10', '9'], 'correct': [0], 'exp': 'Predecessor means the number just before. -10 - 1 = -11', 'type': 'mcq_single'},
                {'q': 'Sum of first five whole numbers is:', 'opts': ['10', '15', '5', '0'], 'correct': [0], 'exp': '0+1+2+3+4 = 10', 'type': 'mcq_single'},
            ]
        elif chapter_title == 'Rational Numbers':
            questions = [
                {'q': 'Which is a rational number?', 'opts': ['3/4', '√3', 'π', 'e'], 'correct': [0], 'exp': 'Rational numbers can be expressed as p/q where q≠0. 3/4 is rational.', 'type': 'mcq_single'},
                {'q': 'The decimal expansion of 1/3 is:', 'opts': ['0.333...', '0.3', '3.0', '0.33'], 'correct': [0], 'exp': '1/3 = 0.333... (non-terminating repeating)', 'type': 'mcq_single'},
                {'q': 'Which of the following are rational numbers? (Select all)', 'opts': ['3/7', '4/8', '√2', '0.5'], 'correct': [0, 1, 3], 'exp': '3/7, 4/8, and 0.5 are rational. √2 is irrational.', 'type': 'mcq_multiple'},
                {'q': 'Select all fractions in lowest terms:', 'opts': ['3/7', '2/5', '4/8', '6/9'], 'correct': [0, 1], 'exp': '3/7 and 2/5 are in lowest terms. 4/8=1/2 and 6/9=2/3 are not.', 'type': 'mcq_multiple'},
                {'q': 'What is the sum of 1/2 and 1/3? (Express as a fraction)', 'opts': [], 'correct': [], 'exp': '1/2 + 1/3 = 3/6 + 2/6 = 5/6', 'type': 'short_answer', 'answer': '5/6'},
                {'q': 'What is the reciprocal of 5/7?', 'opts': [], 'correct': [], 'exp': 'Reciprocal is obtained by interchanging numerator and denominator.', 'type': 'short_answer', 'answer': '7/5'},
                {'q': 'Arrange these fractions in ascending order:', 'opts': ['1/4', '1/3', '1/2', '2/3'], 'correct': [0, 1, 2, 3], 'exp': '1/4 < 1/3 < 1/2 < 2/3', 'type': 'rearrange'},
                {'q': 'Arrange the steps to add two fractions with different denominators:', 'opts': ['Find LCM of denominators', 'Convert to equivalent fractions', 'Add numerators', 'Simplify the result'], 'correct': [0, 1, 2, 3], 'exp': 'Steps: Find LCM → Convert → Add → Simplify', 'type': 'rearrange'},
                {'q': 'Additive inverse of -3/5 is:', 'opts': ['3/5', '-3/5', '5/3', '-5/3'], 'correct': [0], 'exp': 'Additive inverse changes the sign. -(-3/5) = 3/5', 'type': 'mcq_single'},
                {'q': 'The multiplicative identity for rationals is:', 'opts': ['1', '0', '-1', 'None'], 'correct': [0], 'exp': 'Multiplying any rational by 1 gives the same number.', 'type': 'mcq_single'},
            ]
        elif chapter_title == 'Irrational Numbers':
            questions = [
                {'q': '√2 is:', 'opts': ['Irrational', 'Rational', 'Integer', 'Whole number'], 'correct': [0], 'exp': '√2 cannot be expressed as p/q, hence irrational.', 'type': 'mcq_single'},
                {'q': 'Which is an irrational number?', 'opts': ['π', '22/7', '3.14', '0.25'], 'correct': [0], 'exp': 'π is an irrational number with infinite non-repeating decimals.', 'type': 'mcq_single'},
                {'q': 'Which of the following are irrational numbers? (Select all)', 'opts': ['√2', 'π', '√4', '22/7'], 'correct': [0, 1], 'exp': '√2 and π are irrational. √4=2 and 22/7 are rational.', 'type': 'mcq_multiple'},
                {'q': 'Select all true statements about irrational numbers:', 'opts': ['They have non-terminating non-repeating decimals', 'They cannot be expressed as p/q', '√9 is irrational', 'Sum of two irrationals is always irrational'], 'correct': [0, 1], 'exp': 'First two statements are true. √9=3 is rational. Sum of √2 and -√2 is 0 (rational).', 'type': 'mcq_multiple'},
                {'q': 'What is the approximate value of √2? (Round to 3 decimal places)', 'opts': [], 'correct': [], 'exp': '√2 ≈ 1.414', 'type': 'short_answer', 'answer': '1.414'},
                {'q': 'What is the product of √2 and √3?', 'opts': [], 'correct': [], 'exp': '√2 × √3 = √(2×3) = √6', 'type': 'short_answer', 'answer': '√6'},
                {'q': 'Arrange these square roots in ascending order:', 'opts': ['√2', '√3', '√5', '√7'], 'correct': [0, 1, 2, 3], 'exp': '√2 < √3 < √5 < √7 as 2 < 3 < 5 < 7', 'type': 'rearrange'},
                {'q': 'Arrange the steps to prove √2 is irrational:', 'opts': ['Assume √2 = p/q in lowest terms', 'Square both sides: 2 = p²/q²', 'Show p must be even', 'Derive contradiction'], 'correct': [0, 1, 2, 3], 'exp': 'Proof by contradiction follows these steps.', 'type': 'rearrange'},
                {'q': '(√3)² equals:', 'opts': ['3', '9', '√3', '6'], 'correct': [0], 'exp': 'Squaring a square root gives the original number.', 'type': 'mcq_single'},
                {'q': '√7 lies between:', 'opts': ['2 and 3', '3 and 4', '1 and 2', '4 and 5'], 'correct': [0], 'exp': '2² = 4 and 3² = 9. Since 4 < 7 < 9, √7 is between 2 and 3.', 'type': 'mcq_single'},
            ]
        elif chapter_title == 'Real Numbers and Decimal Expansions':
            questions = [
                {'q': 'Real numbers include:', 'opts': ['Both rational and irrational', 'Only rational', 'Only irrational', 'Only integers'], 'correct': [0], 'exp': 'Real numbers = Rational ∪ Irrational', 'type': 'mcq_single'},
                {'q': 'Terminating decimals are:', 'opts': ['Rational', 'Irrational', 'Neither', 'Both'], 'correct': [0], 'exp': 'Terminating decimals can be expressed as fractions.', 'type': 'mcq_single'},
                {'q': 'Which of the following are terminating decimals? (Select all)', 'opts': ['1/4', '1/8', '1/3', '1/5'], 'correct': [0, 1, 3], 'exp': '1/4=0.25, 1/8=0.125, 1/5=0.2 are terminating. 1/3=0.333... is not.', 'type': 'mcq_multiple'},
                {'q': 'Select all true statements:', 'opts': ['0.999... = 1', 'Every rational has terminating decimal', 'Repeating decimals are rational', 'π has a terminating decimal'], 'correct': [0, 2], 'exp': '0.999...=1 is true. Repeating decimals are rational. Not all rationals terminate (like 1/3).', 'type': 'mcq_multiple'},
                {'q': 'What is the decimal expansion of 1/8?', 'opts': [], 'correct': [], 'exp': '1/8 = 0.125 (terminating decimal)', 'type': 'short_answer', 'answer': '0.125'},
                {'q': 'What is the decimal form of 7/8?', 'opts': [], 'correct': [], 'exp': '7 ÷ 8 = 0.875', 'type': 'short_answer', 'answer': '0.875'},
                {'q': 'Arrange the steps to convert 0.235235... to a fraction:', 'opts': ['Let x = 0.235235...', 'Multiply by 1000: 1000x = 235.235...', 'Subtract: 999x = 235', 'Solve: x = 235/999'], 'correct': [0, 1, 2, 3], 'exp': 'Standard method to convert repeating decimals to fractions.', 'type': 'rearrange'},
                {'q': 'Arrange these decimals in ascending order:', 'opts': ['0.125', '0.25', '0.333...', '0.5'], 'correct': [0, 1, 2, 3], 'exp': '0.125 < 0.25 < 0.333... < 0.5', 'type': 'rearrange'},
                {'q': '1/7 has a repeating block of length:', 'opts': ['6', '3', '7', '1'], 'correct': [0], 'exp': '1/7 = 0.142857142857... with period 6', 'type': 'mcq_single'},
                {'q': 'Every real number has a unique:', 'opts': ['Point on number line', 'Fraction form', 'Integer form', 'None'], 'correct': [0], 'exp': 'Every real number corresponds to a unique point on the number line.', 'type': 'mcq_single'},
            ]
        elif chapter_title == 'Laws of Exponents for Real Numbers':
            questions = [
                {'q': 'a^m × a^n equals:', 'opts': ['a^(m+n)', 'a^(mn)', 'a^(m-n)', '(ab)^m'], 'correct': [0], 'exp': 'When multiplying with same base, add exponents.', 'type': 'mcq_single'},
                {'q': '(a^m)^n equals:', 'opts': ['a^(mn)', 'a^(m+n)', 'a^(m-n)', 'a^(m/n)'], 'correct': [0], 'exp': 'Power of a power: multiply exponents.', 'type': 'mcq_single'},
                {'q': 'Which of the following are equal to 1? (Select all)', 'opts': ['5^0', '(-3)^0', '0^0', '1^100'], 'correct': [0, 1, 3], 'exp': 'Any non-zero number to power 0 is 1. 0^0 is undefined. 1^100 = 1.', 'type': 'mcq_multiple'},
                {'q': 'Select all correct exponent laws:', 'opts': ['a^m × a^n = a^(m+n)', 'a^m ÷ a^n = a^(m-n)', '(ab)^n = a^n × b^n', 'a^m + a^n = a^(m+n)'], 'correct': [0, 1, 2], 'exp': 'First three are correct exponent laws. Addition of powers doesn\'t combine like that.', 'type': 'mcq_multiple'},
                {'q': 'Calculate: 2^3 × 2^4 = ?', 'opts': [], 'correct': [], 'exp': '2^3 × 2^4 = 2^7 = 128', 'type': 'short_answer', 'answer': '128'},
                {'q': 'What is 8^(2/3)?', 'opts': [], 'correct': [], 'exp': '8^(2/3) = (8^(1/3))^2 = 2^2 = 4', 'type': 'short_answer', 'answer': '4'},
                {'q': 'Arrange to simplify (2^3)^2 × 2^(-4):', 'opts': ['Apply power of power: 2^6', 'Multiply: 2^6 × 2^(-4)', 'Add exponents: 2^(6-4)', 'Result: 2^2 = 4'], 'correct': [0, 1, 2, 3], 'exp': 'Step by step simplification using exponent laws.', 'type': 'rearrange'},
                {'q': 'Arrange these exponent laws in order of application for a^m × a^n ÷ a^p:', 'opts': ['Identify same base a', 'Apply multiplication law: a^(m+n)', 'Apply division law: a^(m+n-p)', 'Calculate final answer'], 'correct': [0, 1, 2, 3], 'exp': 'Sequential application of exponent laws.', 'type': 'rearrange'},
                {'q': 'a^(1/2) represents:', 'opts': ['√a', 'a/2', '2a', 'a²'], 'correct': [0], 'exp': 'Fractional exponent 1/2 means square root.', 'type': 'mcq_single'},
                {'q': '(ab)^n equals:', 'opts': ['a^n × b^n', 'a^n + b^n', 'ab^n', 'a^(bn)'], 'correct': [0], 'exp': 'Power of a product: distribute the exponent.', 'type': 'mcq_single'},
            ]
        elif chapter_title == 'Number Line and Operations':
            questions = [
                {'q': 'Which point represents -3 on number line?', 'opts': ['3 units left of 0', '3 units right of 0', 'At origin', 'Above 0'], 'correct': [0], 'exp': 'Negative numbers are to the left of zero.', 'type': 'mcq_single'},
                {'q': 'On number line, which is greater?', 'opts': ['5', '-5', '-10', '-100'], 'correct': [0], 'exp': 'Numbers increase as we move right. 5 is rightmost.', 'type': 'mcq_single'},
                {'q': 'Which numbers lie to the right of -2 on the number line? (Select all)', 'opts': ['0', '-1', '-3', '5'], 'correct': [0, 1, 3], 'exp': '0, -1, and 5 are greater than -2. -3 is less than -2.', 'type': 'mcq_multiple'},
                {'q': 'Select all correct statements about the number line:', 'opts': ['Positive numbers are right of 0', 'Negative numbers are left of 0', 'Distance is always positive', '0 is the largest number'], 'correct': [0, 1, 2], 'exp': 'First three statements are correct. 0 is not the largest number.', 'type': 'mcq_multiple'},
                {'q': 'What is the distance between -3 and 4 on the number line?', 'opts': [], 'correct': [], 'exp': 'Distance = |4 - (-3)| = |7| = 7', 'type': 'short_answer', 'answer': '7'},
                {'q': 'What is the midpoint of -2 and 6?', 'opts': [], 'correct': [], 'exp': 'Midpoint = (-2 + 6)/2 = 4/2 = 2', 'type': 'short_answer', 'answer': '2'},
                {'q': 'Arrange these numbers as they appear from left to right on the number line:', 'opts': ['-5', '-2', '0', '3'], 'correct': [0, 1, 2, 3], 'exp': '-5 < -2 < 0 < 3 (left to right)', 'type': 'rearrange'},
                {'q': 'Arrange the steps to represent √2 on a number line:', 'opts': ['Draw a right triangle with legs 1 and 1', 'Calculate hypotenuse = √2', 'Use compass with radius √2', 'Mark the point on number line'], 'correct': [0, 1, 2, 3], 'exp': 'Using Pythagoras theorem to construct √2.', 'type': 'rearrange'},
                {'q': 'Between 0 and 1, there are:', 'opts': ['Infinitely many rationals', 'No rationals', 'Exactly 10 rationals', 'Only integers'], 'correct': [0], 'exp': 'Infinitely many rational numbers exist between any two numbers.', 'type': 'mcq_single'},
                {'q': 'Which represents √3 on number line?', 'opts': ['Between 1 and 2', 'Between 2 and 3', 'At 3', 'Between 0 and 1'], 'correct': [0], 'exp': '1² = 1 < 3 < 4 = 2², so √3 is between 1 and 2.', 'type': 'mcq_single'},
            ]
    
    elif module_name == 'Polynomials':
        if chapter_title == 'Introduction to Polynomials':
            questions = [
                {'q': 'A polynomial in x of degree 2 is called:', 'opts': ['Quadratic', 'Linear', 'Cubic', 'Constant'], 'correct': [0], 'exp': 'Degree 2 polynomial is quadratic.', 'type': 'mcq_single'},
                {'q': 'The degree of polynomial 3x² + 2x + 1 is:', 'opts': ['2', '3', '1', '0'], 'correct': [0], 'exp': 'Highest power of x is 2.', 'type': 'mcq_single'},
                {'q': 'Which of the following are polynomials? (Select all)', 'opts': ['x² + 3x + 1', 'x³ - 5', '1/x + 2', '√x + 1'], 'correct': [0, 1], 'exp': 'Polynomials have non-negative integer exponents. 1/x and √x are not polynomials.', 'type': 'mcq_multiple'},
                {'q': 'Select all monomials from the following:', 'opts': ['5x²', '3', 'x + 1', '7y³'], 'correct': [0, 1, 3], 'exp': 'Monomials have one term. 5x², 3, and 7y³ are monomials.', 'type': 'mcq_multiple'},
                {'q': 'What is the degree of the polynomial 5x³ - 2x² + 7x - 3?', 'opts': [], 'correct': [], 'exp': 'Highest power of x is 3.', 'type': 'short_answer', 'answer': '3'},
                {'q': 'What is the coefficient of x in 5x³ - 2x² + 7x - 3?', 'opts': [], 'correct': [], 'exp': 'Coefficient of x is the number multiplying x.', 'type': 'short_answer', 'answer': '7'},
                {'q': 'Arrange polynomial types by increasing degree:', 'opts': ['Constant (degree 0)', 'Linear (degree 1)', 'Quadratic (degree 2)', 'Cubic (degree 3)'], 'correct': [0, 1, 2, 3], 'exp': 'Constant < Linear < Quadratic < Cubic in terms of degree.', 'type': 'rearrange'},
                {'q': 'Arrange these terms in descending order of degree:', 'opts': ['x⁴', 'x³', 'x²', 'x'], 'correct': [0, 1, 2, 3], 'exp': 'Standard form has terms in descending degree order.', 'type': 'rearrange'},
                {'q': 'The leading coefficient of 4x³ - x² + 2 is:', 'opts': ['4', '-1', '2', '3'], 'correct': [0], 'exp': 'Leading coefficient is the coefficient of highest degree term.', 'type': 'mcq_single'},
                {'q': 'The constant term in x² + 5x - 6 is:', 'opts': ['-6', '5', '1', '0'], 'correct': [0], 'exp': 'Constant term has no variable attached.', 'type': 'mcq_single'},
            ]
        elif chapter_title == 'Zeros of a Polynomial':
            questions = [
                {'q': 'A zero of polynomial p(x) is a value a such that:', 'opts': ['p(a) = 0', 'p(a) = 1', 'p(0) = a', 'p(1) = a'], 'correct': [0], 'exp': 'Zero makes the polynomial equal to 0.', 'type': 'mcq_single'},
                {'q': 'Zero of the polynomial x - 3 is:', 'opts': ['3', '-3', '0', '1'], 'correct': [0], 'exp': 'x - 3 = 0 gives x = 3.', 'type': 'mcq_single'},
                {'q': 'Which are zeros of x² - 1? (Select all)', 'opts': ['1', '-1', '0', '2'], 'correct': [0, 1], 'exp': 'x² - 1 = (x-1)(x+1) = 0 gives x = ±1', 'type': 'mcq_multiple'},
                {'q': 'Which of the following are zeros of x(x-1)(x+2)? (Select all)', 'opts': ['0', '1', '-2', '2'], 'correct': [0, 1, 2], 'exp': 'Set each factor to 0: x=0, x-1=0 → x=1, x+2=0 → x=-2', 'type': 'mcq_multiple'},
                {'q': 'What is the zero of 2x + 6?', 'opts': [], 'correct': [], 'exp': '2x + 6 = 0, x = -3', 'type': 'short_answer', 'answer': '-3'},
                {'q': 'If p(x) = x² - 4, what is p(2)?', 'opts': [], 'correct': [], 'exp': 'p(2) = 4 - 4 = 0, so 2 is a zero.', 'type': 'short_answer', 'answer': '0'},
                {'q': 'Arrange the steps to find zeros of x² - 5x + 6:', 'opts': ['Factorize: (x-2)(x-3)', 'Set each factor to 0', 'Solve: x = 2 or x = 3', 'Verify by substitution'], 'correct': [0, 1, 2, 3], 'exp': 'Finding zeros by factorization method.', 'type': 'rearrange'},
                {'q': 'Arrange polynomial types by maximum number of zeros:', 'opts': ['Constant (0 zeros)', 'Linear (1 zero)', 'Quadratic (2 zeros)', 'Cubic (3 zeros)'], 'correct': [0, 1, 2, 3], 'exp': 'A polynomial of degree n has at most n zeros.', 'type': 'rearrange'},
                {'q': 'If -2 is a zero of p(x), then:', 'opts': ['(x+2) is a factor', '(x-2) is a factor', 'p(-2) = 2', 'p(2) = 0'], 'correct': [0], 'exp': 'If a is a zero, (x-a) is a factor. Here a = -2.', 'type': 'mcq_single'},
                {'q': 'A constant polynomial (non-zero) has:', 'opts': ['No zeros', 'One zero', 'Two zeros', 'Infinite zeros'], 'correct': [0], 'exp': 'A non-zero constant never equals 0.', 'type': 'mcq_single'},
            ]
        elif chapter_title == 'Remainder Theorem':
            questions = [
                {'q': 'By remainder theorem, remainder when p(x) is divided by (x-a) is:', 'opts': ['p(a)', 'p(-a)', 'p(0)', 'a'], 'correct': [0], 'exp': 'Remainder theorem: Remainder = p(a)', 'type': 'mcq_single'},
                {'q': 'Remainder when x² + 2x + 1 is divided by x - 1 is:', 'opts': ['4', '0', '2', '1'], 'correct': [0], 'exp': 'p(1) = 1 + 2 + 1 = 4', 'type': 'mcq_single'},
                {'q': 'For which divisors does the remainder theorem directly apply? (Select all)', 'opts': ['(x - 2)', '(x + 3)', '(x² - 1)', '(2x - 4)'], 'correct': [0, 1], 'exp': 'Remainder theorem applies to linear divisors of form (x - a). (x² - 1) is quadratic.', 'type': 'mcq_multiple'},
                {'q': 'Which statements about remainder theorem are true? (Select all)', 'opts': ['Remainder = p(a) when dividing by (x-a)', 'If remainder is 0, divisor is a factor', 'Works for any polynomial divisor', 'p(a) = 0 means (x-a) is a factor'], 'correct': [0, 1, 3], 'exp': 'Remainder theorem works for linear divisors only, not any polynomial.', 'type': 'mcq_multiple'},
                {'q': 'Find the remainder when x³ + 1 is divided by x + 1.', 'opts': [], 'correct': [], 'exp': 'p(-1) = (-1)³ + 1 = -1 + 1 = 0', 'type': 'short_answer', 'answer': '0'},
                {'q': 'What is the remainder when x⁴ is divided by x - 1?', 'opts': [], 'correct': [], 'exp': 'p(1) = 1⁴ = 1', 'type': 'short_answer', 'answer': '1'},
                {'q': 'Arrange steps to find remainder using remainder theorem:', 'opts': ['Identify divisor (x - a)', 'Find the value of a', 'Calculate p(a)', 'The remainder is p(a)'], 'correct': [0, 1, 2, 3], 'exp': 'Steps to apply remainder theorem.', 'type': 'rearrange'},
                {'q': 'Arrange to verify if (x-2) is a factor of x² - 5x + 6:', 'opts': ['Set a = 2', 'Calculate p(2) = 4 - 10 + 6', 'Check if p(2) = 0', 'Yes, (x-2) is a factor'], 'correct': [0, 1, 2, 3], 'exp': 'Using remainder theorem to verify factors.', 'type': 'rearrange'},
                {'q': 'If p(x) divided by (x-k) gives remainder 5, then p(k) = ?', 'opts': ['5', 'k', '0', '-5'], 'correct': [0], 'exp': 'By remainder theorem, remainder = p(k) = 5', 'type': 'mcq_single'},
                {'q': 'If remainder is 0, then the divisor is a:', 'opts': ['Factor', 'Multiple', 'Zero', 'Coefficient'], 'correct': [0], 'exp': 'Zero remainder means the divisor is a factor.', 'type': 'mcq_single'},
            ]
        elif chapter_title == 'Factor Theorem':
            questions = [
                {'q': '(x - a) is a factor of p(x) if and only if:', 'opts': ['p(a) = 0', 'p(a) = 1', 'p(0) = a', 'p(-a) = 0'], 'correct': [0], 'exp': 'Factor theorem: (x-a) is factor iff p(a) = 0', 'type': 'mcq_single'},
                {'q': 'Is (x - 2) a factor of x² - 5x + 6?', 'opts': ['Yes', 'No', 'Cannot determine', 'Partially'], 'correct': [0], 'exp': 'p(2) = 4 - 10 + 6 = 0, so yes.', 'type': 'mcq_single'},
                {'q': 'Which are factors of x² - 9? (Select all)', 'opts': ['(x - 3)', '(x + 3)', '(x - 9)', '(x + 9)'], 'correct': [0, 1], 'exp': 'x² - 9 = (x-3)(x+3) using difference of squares.', 'type': 'mcq_multiple'},
                {'q': 'If (x - 1), (x - 2), and (x - 3) are factors of a polynomial, then: (Select all true)', 'opts': ['p(1) = 0', 'p(2) = 0', 'p(3) = 0', 'p(0) = 0'], 'correct': [0, 1, 2], 'exp': 'Each factor gives a zero: 1, 2, and 3 are zeros.', 'type': 'mcq_multiple'},
                {'q': 'Find k if (x - 1) is a factor of x² - kx + 2.', 'opts': [], 'correct': [], 'exp': 'p(1) = 1 - k + 2 = 0, so k = 3', 'type': 'short_answer', 'answer': '3'},
                {'q': 'Is (x + 3) a factor of x³ + 27? (Answer Yes or No)', 'opts': [], 'correct': [], 'exp': 'p(-3) = (-3)³ + 27 = -27 + 27 = 0, so yes.', 'type': 'short_answer', 'answer': 'Yes'},
                {'q': 'Arrange steps to check if (x-1) is a factor of x³ - 6x² + 11x - 6:', 'opts': ['Substitute x = 1 in p(x)', 'Calculate: 1 - 6 + 11 - 6', 'Result: 0', 'Conclusion: (x-1) is a factor'], 'correct': [0, 1, 2, 3], 'exp': 'Using factor theorem to verify.', 'type': 'rearrange'},
                {'q': 'Arrange the relationship between theorems:', 'opts': ['Remainder Theorem is general', 'Factor Theorem is specific case', 'When remainder = 0', 'Divisor becomes a factor'], 'correct': [0, 1, 2, 3], 'exp': 'Factor theorem is a special case of remainder theorem.', 'type': 'rearrange'},
                {'q': 'The factor theorem is a special case of:', 'opts': ['Remainder theorem', 'Binomial theorem', 'Pythagoras theorem', 'None'], 'correct': [0], 'exp': 'When remainder = 0, factor theorem applies.', 'type': 'mcq_single'},
                {'q': 'If p(3) = 0, which is a factor of p(x)?', 'opts': ['(x - 3)', '(x + 3)', '(x - 1/3)', '3x'], 'correct': [0], 'exp': 'p(3) = 0 means (x - 3) is a factor.', 'type': 'mcq_single'},
            ]
        elif chapter_title == 'Factorization of Polynomials':
            questions = [
                {'q': 'Factorize: x² - 5x + 6', 'opts': ['(x-2)(x-3)', '(x+2)(x+3)', '(x-1)(x-6)', '(x+1)(x+6)'], 'correct': [0], 'exp': 'Find factors of 6 that add to 5: 2 and 3.', 'type': 'mcq_single'},
                {'q': 'Factorize: x² - 16', 'opts': ['(x-4)(x+4)', '(x-8)(x+2)', '(x-4)²', '(x+4)²'], 'correct': [0], 'exp': 'Difference of squares: a² - b² = (a-b)(a+b)', 'type': 'mcq_single'},
                {'q': 'Which expressions are perfect squares? (Select all)', 'opts': ['x² + 6x + 9', '4x² - 12x + 9', 'x² - 16', 'x² + 4x + 4'], 'correct': [0, 1, 3], 'exp': '(x+3)², (2x-3)², (x+2)² are perfect squares. x²-16 is difference of squares.', 'type': 'mcq_multiple'},
                {'q': 'Which factorization methods are correctly matched? (Select all)', 'opts': ['x² - 9 → Difference of squares', 'x² + 6x + 9 → Perfect square', 'x³ + 8 → Sum of cubes', 'x² - x - 6 → Splitting middle term'], 'correct': [0, 1, 2, 3], 'exp': 'All four methods are correctly identified.', 'type': 'mcq_multiple'},
                {'q': 'What is the common factor of 6x² + 9x?', 'opts': [], 'correct': [], 'exp': 'GCD of 6 and 9 is 3, both have x. Common factor is 3x.', 'type': 'short_answer', 'answer': '3x'},
                {'q': 'Factorize x² - x - 6. Write as (x+a)(x+b) where a < b.', 'opts': [], 'correct': [], 'exp': 'Product = -6, sum = -1: use -3 and 2. Answer: (x+2)(x-3)', 'type': 'short_answer', 'answer': '(x+2)(x-3)'},
                {'q': 'Arrange steps to factorize x² + 5x + 6:', 'opts': ['Find two numbers with product 6', 'Find two numbers with sum 5', 'Numbers are 2 and 3', 'Write as (x+2)(x+3)'], 'correct': [0, 1, 2, 3], 'exp': 'Splitting middle term method.', 'type': 'rearrange'},
                {'q': 'Arrange factorization identities from simplest to complex:', 'opts': ['a² - b² = (a-b)(a+b)', '(a+b)² = a² + 2ab + b²', 'a³ + b³ = (a+b)(a²-ab+b²)', 'a³ - b³ = (a-b)(a²+ab+b²)'], 'correct': [0, 1, 2, 3], 'exp': 'Difference of squares, perfect square, sum of cubes, difference of cubes.', 'type': 'rearrange'},
                {'q': 'Factorize: x³ + 8', 'opts': ['(x+2)(x²-2x+4)', '(x-2)(x²+2x+4)', '(x+8)(x²-1)', '(x+2)³'], 'correct': [0], 'exp': 'Sum of cubes: a³+b³ = (a+b)(a²-ab+b²)', 'type': 'mcq_single'},
                {'q': 'Which cannot be factored over integers?', 'opts': ['x² + 1', 'x² - 1', 'x² + 2x + 1', 'x² - 4x + 4'], 'correct': [0], 'exp': 'x² + 1 has no real factors.', 'type': 'mcq_single'},
            ]
        elif chapter_title == 'Algebraic Identities':
            questions = [
                {'q': '(a + b)² equals:', 'opts': ['a² + 2ab + b²', 'a² + b²', 'a² - 2ab + b²', 'a² + ab + b²'], 'correct': [0], 'exp': 'Square of sum identity.', 'type': 'mcq_single'},
                {'q': '(a - b)² equals:', 'opts': ['a² - 2ab + b²', 'a² + 2ab + b²', 'a² - b²', 'a² + b²'], 'correct': [0], 'exp': 'Square of difference identity.', 'type': 'mcq_single'},
                {'q': 'Which identities are correct? (Select all)', 'opts': ['(a+b)² = a² + 2ab + b²', 'a² - b² = (a+b)(a-b)', '(a+b)³ = a³ + b³', 'a³ + b³ = (a+b)(a²-ab+b²)'], 'correct': [0, 1, 3], 'exp': '(a+b)³ ≠ a³ + b³. The cube of sum has additional terms.', 'type': 'mcq_multiple'},
                {'q': 'Select all expressions that equal a² + b²:', 'opts': ['(a+b)² - 2ab', '(a-b)² + 2ab', '(a+b)²', '(a-b)² - 2ab'], 'correct': [0, 1], 'exp': '(a+b)² - 2ab = a² + b² and (a-b)² + 2ab = a² + b²', 'type': 'mcq_multiple'},
                {'q': 'Using identity, calculate 99². (Hint: 99 = 100-1)', 'opts': [], 'correct': [], 'exp': '99² = (100-1)² = 10000 - 200 + 1 = 9801', 'type': 'short_answer', 'answer': '9801'},
                {'q': 'Calculate 103 × 97 using the identity a² - b².', 'opts': [], 'correct': [], 'exp': '(100+3)(100-3) = 100² - 9 = 9991', 'type': 'short_answer', 'answer': '9991'},
                {'q': 'Arrange the expansion of (a + b)³:', 'opts': ['a³', '+ 3a²b', '+ 3ab²', '+ b³'], 'correct': [0, 1, 2, 3], 'exp': '(a+b)³ = a³ + 3a²b + 3ab² + b³', 'type': 'rearrange'},
                {'q': 'Arrange these algebraic identities from basic to advanced:', 'opts': ['a² - b² = (a-b)(a+b)', '(a+b)² = a² + 2ab + b²', '(a+b)³ = a³ + 3a²b + 3ab² + b³', 'a³ + b³ = (a+b)(a²-ab+b²)'], 'correct': [0, 1, 2, 3], 'exp': 'Progressing from squares to cubes.', 'type': 'rearrange'},
                {'q': '(x + 2)² - (x - 2)² equals:', 'opts': ['8x', '4x', '0', '4x²'], 'correct': [0], 'exp': 'Using a² - b² = (a+b)(a-b): = (2x)(4) = 8x', 'type': 'mcq_single'},
                {'q': 'If a + b = 5 and ab = 6, then a² + b² = ?', 'opts': ['13', '25', '11', '19'], 'correct': [0], 'exp': '(a+b)² = a² + 2ab + b², so 25 = a² + b² + 12, a² + b² = 13', 'type': 'mcq_single'},
            ]
    
    if not questions:
        questions = generate_default_questions(module_name, chapter_title)
    
    return questions


def get_hots_questions(module_name, chapter_title):
    """Generate 3 HOTS questions for a chapter."""
    hots = []
    
    if module_name == 'Number Systems':
        if chapter_title == 'Introduction to Number Systems':
            hots = [
                {'q': 'If a number is both a whole number and an integer but not a natural number, what is that number?', 'opts': ['0', '1', '-1', 'Does not exist'], 'correct': [0], 'exp': 'Zero is the only whole number that is not natural, and it is also an integer.', 'type': 'mcq_single'},
                {'q': 'A set S contains all positive integers less than 10 that are not divisible by 2 or 3. How many elements does S have?', 'opts': [], 'correct': [], 'exp': 'Numbers: 1, 5, 7 (not divisible by 2 or 3) = 3 elements', 'type': 'short_answer', 'answer': '3'},
                {'q': 'If the sum of three consecutive integers is 42, which statements are true? (Select all)', 'opts': ['The middle integer is 14', 'The integers are 13, 14, 15', 'Product of smallest and largest is 195', 'The largest integer is 16'], 'correct': [0, 1, 2], 'exp': 'Sum = 3n = 42, n = 14. Integers: 13, 14, 15. Product = 13 × 15 = 195', 'type': 'mcq_multiple'},
            ]
        elif chapter_title == 'Rational Numbers':
            hots = [
                {'q': 'The sum of a rational number and its reciprocal is 26/5. Find the number.', 'opts': ['5 or 1/5', '5 only', '1/5 only', '26/5'], 'correct': [0], 'exp': 'Let x be the number. x + 1/x = 26/5. Solving: 5x² - 26x + 5 = 0. x = 5 or 1/5', 'type': 'mcq_single'},
                {'q': 'A fraction becomes 4/5 when 1 is added to both numerator and denominator. It becomes 1/2 when 5 is subtracted from both. Find the original numerator.', 'opts': [], 'correct': [], 'exp': 'Let fraction be a/b. (a+1)/(b+1) = 4/5 and (a-5)/(b-5) = 1/2. Solving: a = 7, b = 9', 'type': 'short_answer', 'answer': '7'},
                {'q': 'Arrange the steps to find two rational numbers whose sum is 2/3 and product is -8/9:', 'opts': ['Form equation: x² - (2/3)x + (-8/9) = 0', 'Multiply by 9: 9x² - 6x - 8 = 0', 'Factorize: (3x-4)(3x+2) = 0', 'Solutions: x = 4/3 or x = -2/3'], 'correct': [0, 1, 2, 3], 'exp': 'Using sum and product to form quadratic equation.', 'type': 'rearrange'},
            ]
        elif chapter_title == 'Irrational Numbers':
            hots = [
                {'q': 'Prove that √2 + √3 is irrational. If we assume it is rational and equals p/q, what contradiction arises?', 'opts': ['√6 would be rational', '√2 would be rational', '√3 would be rational', 'All are correct'], 'correct': [0], 'exp': 'If √2 + √3 = p/q, then squaring and rearranging shows √6 = (p²/q² - 5)/2, making √6 rational - contradiction', 'type': 'mcq_single'},
                {'q': 'The area of a square is 5 sq units. Is the perimeter rational or irrational? (Answer: Rational or Irrational)', 'opts': [], 'correct': [], 'exp': 'Side = √5 (irrational). Perimeter = 4√5 (irrational × rational = irrational)', 'type': 'short_answer', 'answer': 'Irrational'},
                {'q': 'Which statements about √2 + √3 are true? (Select all)', 'opts': ['It is irrational', 'Its square is 5 + 2√6', 'It equals approximately 3.146', 'It can be expressed as a fraction'], 'correct': [0, 1, 2], 'exp': '√2 + √3 ≈ 1.414 + 1.732 = 3.146. (√2+√3)² = 2 + 2√6 + 3 = 5 + 2√6', 'type': 'mcq_multiple'},
            ]
        else:
            hots = generate_default_hots(module_name, chapter_title)
    
    elif module_name == 'Polynomials':
        if chapter_title == 'Introduction to Polynomials':
            hots = [
                {'q': 'If the polynomial p(x) = x³ - 6x² + 11x - 6 has three positive integer zeros, find their product.', 'opts': ['6', '11', '1', '18'], 'correct': [0], 'exp': 'By Vieta\'s formulas, product of zeros = -(-6)/1 = 6. The zeros are 1, 2, 3.', 'type': 'mcq_single'},
                {'q': 'A polynomial p(x) leaves remainder 2 when divided by (x-1) and remainder 4 when divided by (x-2). If p(x) is linear, find p(3).', 'opts': [], 'correct': [], 'exp': 'p(1) = 2, p(2) = 4. Linear: p(x) = ax + b. a + b = 2, 2a + b = 4. a = 2, b = 0. p(3) = 6', 'type': 'short_answer', 'answer': '6'},
                {'q': 'For polynomial (x² + 1)³ × (x³ + 2)², which are true? (Select all)', 'opts': ['Degree is 12', 'It has real zeros', 'Leading coefficient is 1', 'It is a polynomial of degree 15'], 'correct': [0, 2], 'exp': 'Degree of (x² + 1)³ = 6, degree of (x³ + 2)² = 6. Total = 12. Leading coefficient = 1×1 = 1.', 'type': 'mcq_multiple'},
            ]
        elif chapter_title == 'Zeros of a Polynomial':
            hots = [
                {'q': 'If α and β are zeros of x² - 5x + 6, find the value of α³ + β³.', 'opts': [], 'correct': [], 'exp': 'α + β = 5, αβ = 6. α³ + β³ = (α + β)³ - 3αβ(α + β) = 125 - 90 = 35', 'type': 'short_answer', 'answer': '35'},
                {'q': 'Find a quadratic polynomial whose zeros are 2 + √3 and 2 - √3.', 'opts': ['x² - 4x + 1', 'x² + 4x + 1', 'x² - 4x - 1', 'x² + 4x - 1'], 'correct': [0], 'exp': 'Sum = 4, Product = 4 - 3 = 1. Polynomial: x² - 4x + 1', 'type': 'mcq_single'},
                {'q': 'Arrange steps to find α³ + β³ given zeros of a quadratic:', 'opts': ['Find sum (α + β) and product (αβ) from coefficients', 'Use identity: α³ + β³ = (α + β)³ - 3αβ(α + β)', 'Substitute values', 'Calculate final answer'], 'correct': [0, 1, 2, 3], 'exp': 'Using Vieta\'s formulas and algebraic identities.', 'type': 'rearrange'},
            ]
        else:
            hots = generate_default_hots(module_name, chapter_title)
    
    if not hots:
        hots = generate_default_hots(module_name, chapter_title)
    
    return hots


def generate_default_questions(module_name, chapter_title):
    """Generate generic questions when specific ones aren't available."""
    questions = []
    question_types = ['mcq_single', 'mcq_single', 'mcq_multiple', 'mcq_multiple',
                      'short_answer', 'short_answer', 'rearrange', 'rearrange',
                      'mcq_single', 'mcq_single']

    for i in range(10):
        q_type = question_types[i]

        if q_type == 'mcq_single':
            questions.append({
                'q': f'{chapter_title} - Question {i+1}: A fundamental concept question related to {module_name}.',
                'opts': [f'Correct Answer for Q{i+1}', 'Wrong Option A', 'Wrong Option B', 'Wrong Option C'],
                'correct': [0],
                'exp': f'This is the explanation for question {i+1} about {chapter_title} in {module_name}.',
                'type': 'mcq_single'
            })
        elif q_type == 'mcq_multiple':
            questions.append({
                'q': f'{chapter_title} - Question {i+1}: Select all correct options related to {module_name}.',
                'opts': ['Correct Option 1', 'Correct Option 2', 'Wrong Option A', 'Wrong Option B'],
                'correct': [0, 1],
                'exp': f'This is the explanation for question {i+1} about {chapter_title} in {module_name}.',
                'type': 'mcq_multiple'
            })
        elif q_type == 'short_answer':
            questions.append({
                'q': f'{chapter_title} - Question {i+1}: Provide a short answer about {module_name}.',
                'opts': [],
                'correct': [],
                'exp': f'The answer involves understanding {chapter_title} concepts in {module_name}.',
                'type': 'short_answer',
                'answer': 'Expected Answer'
            })
        elif q_type == 'rearrange':
            questions.append({
                'q': f'{chapter_title} - Question {i+1}: Arrange the following in correct order:',
                'opts': ['Step 1', 'Step 2', 'Step 3', 'Step 4'],
                'correct': [0, 1, 2, 3],
                'exp': f'The correct order follows the logical sequence of {chapter_title}.',
                'type': 'rearrange'
            })

    return questions


def generate_default_hots(module_name, chapter_title):
    """Generate generic HOTS questions when specific ones aren't available."""
    hots = []
    hots_types = ['mcq_single', 'short_answer', 'mcq_multiple']

    for i in range(3):
        h_type = hots_types[i]

        if h_type == 'mcq_single':
            hots.append({
                'q': f'{chapter_title} - HOTS {i+1}: An advanced problem-solving question on {module_name}.',
                'opts': ['Correct Complex Answer', 'Wrong Complex A', 'Wrong Complex B', 'Wrong Complex C'],
                'correct': [0],
                'exp': f'This is a detailed explanation for HOTS question {i+1} requiring higher-order thinking.',
                'type': 'mcq_single'
            })
        elif h_type == 'short_answer':
            hots.append({
                'q': f'{chapter_title} - HOTS {i+1}: Solve this advanced problem on {module_name}.',
                'opts': [],
                'correct': [],
                'exp': f'This requires deep understanding of {chapter_title} and application of multiple concepts.',
                'type': 'short_answer',
                'answer': 'Complex Answer'
            })
        elif h_type == 'mcq_multiple':
            hots.append({
                'q': f'{chapter_title} - HOTS {i+1}: Select all correct conclusions about {module_name}.',
                'opts': ['Correct Conclusion 1', 'Correct Conclusion 2', 'Wrong Conclusion A', 'Wrong Conclusion B'],
                'correct': [0, 1],
                'exp': f'This requires analyzing multiple aspects of {chapter_title}.',
                'type': 'mcq_multiple'
            })

    return hots


class Command(BaseCommand):
    help = 'Populate Math subject with modules, chapters, questions, and HOTS'

    def add_arguments(self, parser):
        parser.add_argument(
            '--clear-existing',
            action='store_true',
            help='Delete all existing modules and content for this subject before creating new ones',
        )

    def handle(self, *args, **options):
        clear_existing = options.get('clear_existing', False)

        try:
            subject = Subject.objects.get(name__iexact=SUBJECT_NAME)
            self.stdout.write(f'Found subject: {subject.name}')
        except Subject.DoesNotExist:
            subject = Subject.objects.create(
                name=SUBJECT_NAME,
                code=SUBJECT_NAME[:3].upper(),
                description=f'{SUBJECT_NAME} subject for Class 9',
                is_active=True,
            )
            self.stdout.write(self.style.SUCCESS(f'Created subject: {subject.name}'))

        if clear_existing:
            self.stdout.write('Deleting existing data for this subject...')
            ChapterHOTS.objects.filter(chapter__module__subject=subject).delete()
            ModuleContent.objects.filter(chapter__module__subject=subject).delete()
            ModuleChapter.objects.filter(module__subject=subject).delete()
            Module.objects.filter(subject=subject).delete()
            self.stdout.write(self.style.SUCCESS('Existing data deleted.'))

        accounts = list(Account.objects.filter(is_superuser=False)[:1])
        if not accounts:
            accounts = list(Account.objects.filter(is_superuser=True)[:1])
        created_by = accounts[0] if accounts else None

        stats = {
            'modules': 0, 'chapters': 0, 'questions': 0,
            'options': 0, 'module_contents': 0, 'hots': 0,
        }

        with transaction.atomic():
            for module_order, (module_name, module_data) in enumerate(MATH_MODULES.items(), start=1):
                self.stdout.write(f'\nCreating module: {module_name}')
                
                module, created = Module.objects.get_or_create(
                    name=module_name,
                    subject=subject,
                    defaults={
                        'description': module_data['description'],
                        'order': module_order,
                        'is_active': True,
                        'is_enabled': True,
                        'created_by': created_by,
                    }
                )
                if created:
                    stats['modules'] += 1

                for chapter_order, chapter_data in enumerate(module_data['chapters'], start=1):
                    chapter_title = chapter_data['title']
                    
                    chapter, created = ModuleChapter.objects.get_or_create(
                        module=module,
                        order=chapter_order,
                        defaults={
                            'title': chapter_title,
                            'description': chapter_data['description'],
                            'is_enabled': True,
                            'is_important': chapter_order <= 2,
                            'has_hots': True,
                            'created_by': created_by,
                        }
                    )
                    if created:
                        stats['chapters'] += 1
                    else:
                        continue

                    chapter_questions = get_chapter_questions(module_name, chapter_title)
                    
                    for q_order, q_data in enumerate(chapter_questions[:10], start=1):
                        q_type = q_data.get('type', 'mcq_single')
                        
                        question = Question.objects.create(
                            question_text=q_data['q'],
                            question_type=q_type,
                            exp_points=random.randint(10, 30),
                            difficulty_level=random.choice(['easy', 'medium', 'hard']),
                            explanation=q_data['exp'],
                            is_active=True,
                            is_hots=False,
                            created_by=created_by,
                        )
                        stats['questions'] += 1

                        if q_type in ['mcq_single', 'mcq_multiple', 'rearrange']:
                            correct_indices = q_data.get('correct', [])
                            for opt_order, opt_text in enumerate(q_data['opts'], start=1):
                                is_correct = (opt_order - 1) in correct_indices
                                Option.objects.get_or_create(
                                    question=question,
                                    option_text=opt_text,
                                    defaults={
                                        'is_correct': is_correct,
                                        'order': opt_order,
                                    }
                                )
                                stats['options'] += 1

                        ModuleContent.objects.get_or_create(
                            chapter=chapter,
                            order=q_order,
                            defaults={
                                'content_type': 'question',
                                'question': question,
                                'created_by': created_by,
                            }
                        )
                        stats['module_contents'] += 1

                    hots_questions = get_hots_questions(module_name, chapter_title)
                    
                    for hots_order, hots_data in enumerate(hots_questions[:3], start=1):
                        h_type = hots_data.get('type', 'mcq_single')
                        
                        hots_question = Question.objects.create(
                            question_text=hots_data['q'],
                            question_type=h_type,
                            exp_points=random.randint(40, 60),
                            difficulty_level='hard',
                            explanation=hots_data['exp'],
                            is_active=True,
                            is_hots=True,
                            created_by=created_by,
                        )
                        stats['questions'] += 1

                        if h_type in ['mcq_single', 'mcq_multiple', 'rearrange']:
                            correct_indices = hots_data.get('correct', [])
                            for opt_order, opt_text in enumerate(hots_data['opts'], start=1):
                                is_correct = (opt_order - 1) in correct_indices
                                Option.objects.get_or_create(
                                    question=hots_question,
                                    option_text=opt_text,
                                    defaults={
                                        'is_correct': is_correct,
                                        'order': opt_order,
                                    }
                                )
                                stats['options'] += 1

                        ChapterHOTS.objects.get_or_create(
                            chapter=chapter,
                            question=hots_question,
                            defaults={
                                'order': hots_order,
                                'created_by': created_by,
                            }
                        )
                        stats['hots'] += 1

                    self.stdout.write(f'  ✓ {chapter_title}: {len(chapter_questions[:10])} questions + {len(hots_questions[:3])} HOTS')

        self.stdout.write('\n' + '=' * 70)
        self.stdout.write(self.style.SUCCESS(f'SUCCESS! {SUBJECT_NAME} subject populated:'))
        self.stdout.write('=' * 70)
        self.stdout.write(f'  Modules: {stats["modules"]}')
        self.stdout.write(f'  Chapters: {stats["chapters"]}')
        self.stdout.write(f'  Questions: {stats["questions"]}')
        self.stdout.write(f'  HOTS: {stats["hots"]}')
        self.stdout.write('=' * 70)
