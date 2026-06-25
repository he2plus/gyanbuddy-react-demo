"""
Django management command to create missions for all subjects with questions.
Creates missions for today and tomorrow with 4 questions of each type:
- mcq_single (4 questions)
- mcq_multiple (4 questions)
- short_answer (4 questions)
- rearrange (4 questions)
Total: 16 questions per mission
"""

from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone
from datetime import timedelta
from gyaan_buddy.subjects.models import (
    Subject, Question, Option
)
from gyaan_buddy.users.models import (
    Account, Class, School, Mission, MissionQuestion
)
import random


MISSION_QUESTIONS = {
    'Math': {
        'mcq_single': [
            {'q': 'What is 15 + 27?', 'opts': ['42', '43', '40', '45'], 'correct': 0, 'exp': '15 + 27 = 42'},
            {'q': 'What is the square root of 144?', 'opts': ['12', '14', '11', '13'], 'correct': 0, 'exp': '√144 = 12'},
            {'q': 'What is 8 × 7?', 'opts': ['56', '54', '58', '52'], 'correct': 0, 'exp': '8 × 7 = 56'},
            {'q': 'What is 100 ÷ 4?', 'opts': ['25', '20', '30', '24'], 'correct': 0, 'exp': '100 ÷ 4 = 25'},
            {'q': 'What is 17 - 9?', 'opts': ['8', '7', '9', '6'], 'correct': 0, 'exp': '17 - 9 = 8'},
            {'q': 'What is 3³?', 'opts': ['27', '9', '18', '81'], 'correct': 0, 'exp': '3³ = 3 × 3 × 3 = 27'},
            {'q': 'What is the value of π (approximately)?', 'opts': ['3.14', '2.14', '3.41', '4.13'], 'correct': 0, 'exp': 'π ≈ 3.14159...'},
            {'q': 'What is 45% of 200?', 'opts': ['90', '80', '100', '85'], 'correct': 0, 'exp': '45% of 200 = (45/100) × 200 = 90'},
        ],
        'mcq_multiple': [
            {'q': 'Which of the following are prime numbers? (Select all that apply)', 'opts': ['7', '11', '9', '15'], 'correct': [0, 1], 'exp': '7 and 11 are prime numbers. 9 = 3×3, 15 = 3×5 are not prime.'},
            {'q': 'Select all even numbers:', 'opts': ['24', '36', '17', '45'], 'correct': [0, 1], 'exp': '24 and 36 are even (divisible by 2). 17 and 45 are odd.'},
            {'q': 'Which are factors of 24?', 'opts': ['4', '6', '5', '7'], 'correct': [0, 1], 'exp': '24 = 4 × 6, so both 4 and 6 are factors.'},
            {'q': 'Select all multiples of 5:', 'opts': ['15', '25', '18', '22'], 'correct': [0, 1], 'exp': '15 = 5×3, 25 = 5×5 are multiples of 5.'},
            {'q': 'Which numbers are divisible by 3?', 'opts': ['12', '21', '14', '19'], 'correct': [0, 1], 'exp': '12 and 21 are divisible by 3 (digit sum divisible by 3).'},
            {'q': 'Select all perfect squares:', 'opts': ['16', '49', '20', '30'], 'correct': [0, 1], 'exp': '16 = 4², 49 = 7² are perfect squares.'},
            {'q': 'Which are composite numbers?', 'opts': ['12', '15', '7', '11'], 'correct': [0, 1], 'exp': '12 and 15 have factors other than 1 and themselves.'},
            {'q': 'Select all rational numbers:', 'opts': ['3/4', '0.5', '√2', 'π'], 'correct': [0, 1], 'exp': '3/4 and 0.5 can be expressed as fractions. √2 and π are irrational.'},
        ],
        'short_answer': [
            {'q': 'Calculate: 234 + 567 = ?', 'answer': '801', 'exp': '234 + 567 = 801'},
            {'q': 'What is 15% of 80?', 'answer': '12', 'exp': '15% of 80 = (15/100) × 80 = 12'},
            {'q': 'Solve: x + 7 = 15. What is x?', 'answer': '8', 'exp': 'x = 15 - 7 = 8'},
            {'q': 'What is the area of a square with side 9 cm?', 'answer': '81', 'exp': 'Area = side² = 9² = 81 sq cm'},
            {'q': 'How many degrees are in a right angle?', 'answer': '90', 'exp': 'A right angle measures 90 degrees.'},
            {'q': 'What is the perimeter of a rectangle with length 8 and width 5?', 'answer': '26', 'exp': 'Perimeter = 2(l + w) = 2(8 + 5) = 26'},
            {'q': 'What is the next prime number after 17?', 'answer': '19', 'exp': '18 is not prime (divisible by 2), but 19 is prime.'},
            {'q': 'Calculate: 144 ÷ 12 = ?', 'answer': '12', 'exp': '144 ÷ 12 = 12'},
        ],
        'rearrange': [
            {'q': 'Arrange in ascending order: 45, 23, 67, 12', 'opts': ['12', '23', '45', '67'], 'correct_order': [0, 1, 2, 3], 'exp': 'Ascending: 12 < 23 < 45 < 67'},
            {'q': 'Arrange steps to solve 2x + 4 = 10', 'opts': ['Subtract 4 from both sides', 'Divide by 2', 'Get x = 3', 'Start with equation'], 'correct_order': [3, 0, 1, 2], 'exp': 'Steps: Start → Subtract 4 → Divide by 2 → Get x = 3'},
            {'q': 'Arrange fractions from smallest to largest: 1/2, 1/4, 3/4, 1/8', 'opts': ['1/8', '1/4', '1/2', '3/4'], 'correct_order': [0, 1, 2, 3], 'exp': '1/8 < 1/4 < 1/2 < 3/4'},
            {'q': 'Arrange numbers in descending order: 5², 2³, 3², 4¹', 'opts': ['25', '9', '8', '4'], 'correct_order': [0, 1, 2, 3], 'exp': '5²=25 > 3²=9 > 2³=8 > 4¹=4'},
            {'q': 'Arrange the operations in BODMAS order', 'opts': ['Brackets', 'Orders', 'Division/Multiplication', 'Addition/Subtraction'], 'correct_order': [0, 1, 2, 3], 'exp': 'BODMAS: Brackets, Orders, Division/Multiplication, Addition/Subtraction'},
            {'q': 'Arrange angles from smallest to largest: Right, Acute, Obtuse, Straight', 'opts': ['Acute', 'Right', 'Obtuse', 'Straight'], 'correct_order': [0, 1, 2, 3], 'exp': 'Acute < 90° < Right = 90° < Obtuse < 180° < Straight = 180°'},
            {'q': 'Arrange decimals in ascending order: 0.5, 0.25, 0.75, 0.1', 'opts': ['0.1', '0.25', '0.5', '0.75'], 'correct_order': [0, 1, 2, 3], 'exp': '0.1 < 0.25 < 0.5 < 0.75'},
            {'q': 'Arrange the steps to find LCM of 12 and 18', 'opts': ['Find prime factors of both', 'Take highest power of each prime', 'Multiply: 2² × 3² = 36', 'LCM = 36'], 'correct_order': [0, 1, 2, 3], 'exp': 'Steps: Find primes → Take highest powers → Multiply → Get LCM'},
        ],
    },
    'Science': {
        'mcq_single': [
            {'q': 'What is the chemical symbol for water?', 'opts': ['H₂O', 'CO₂', 'NaCl', 'O₂'], 'correct': 0, 'exp': 'Water is composed of 2 hydrogen atoms and 1 oxygen atom: H₂O'},
            {'q': 'Which planet is known as the Red Planet?', 'opts': ['Mars', 'Jupiter', 'Venus', 'Saturn'], 'correct': 0, 'exp': 'Mars appears red due to iron oxide (rust) on its surface.'},
            {'q': 'What is the powerhouse of the cell?', 'opts': ['Mitochondria', 'Nucleus', 'Ribosome', 'Golgi body'], 'correct': 0, 'exp': 'Mitochondria produce ATP, the energy currency of cells.'},
            {'q': 'What is the speed of light approximately?', 'opts': ['300,000 km/s', '150,000 km/s', '500,000 km/s', '100,000 km/s'], 'correct': 0, 'exp': 'Speed of light in vacuum ≈ 299,792 km/s ≈ 300,000 km/s'},
            {'q': 'Which gas do plants absorb during photosynthesis?', 'opts': ['Carbon dioxide', 'Oxygen', 'Nitrogen', 'Hydrogen'], 'correct': 0, 'exp': 'Plants absorb CO₂ and release O₂ during photosynthesis.'},
            {'q': 'What is the largest organ in the human body?', 'opts': ['Skin', 'Liver', 'Heart', 'Brain'], 'correct': 0, 'exp': 'Skin is the largest organ, covering about 2 square meters.'},
            {'q': 'What is the atomic number of Carbon?', 'opts': ['6', '12', '8', '14'], 'correct': 0, 'exp': 'Carbon has 6 protons, so its atomic number is 6.'},
            {'q': 'Which force keeps planets in orbit around the Sun?', 'opts': ['Gravity', 'Magnetism', 'Friction', 'Tension'], 'correct': 0, 'exp': 'Gravitational force from the Sun keeps planets in their orbits.'},
        ],
        'mcq_multiple': [
            {'q': 'Select all noble gases:', 'opts': ['Helium', 'Neon', 'Oxygen', 'Nitrogen'], 'correct': [0, 1], 'exp': 'Helium and Neon are noble gases with full outer shells.'},
            {'q': 'Which are examples of renewable energy?', 'opts': ['Solar', 'Wind', 'Coal', 'Oil'], 'correct': [0, 1], 'exp': 'Solar and wind are renewable; coal and oil are fossil fuels.'},
            {'q': 'Select all states of matter:', 'opts': ['Solid', 'Liquid', 'Light', 'Sound'], 'correct': [0, 1], 'exp': 'Solid, liquid, gas, and plasma are states of matter.'},
            {'q': 'Which are parts of an atom?', 'opts': ['Proton', 'Neutron', 'Molecule', 'Ion'], 'correct': [0, 1], 'exp': 'Atoms have protons, neutrons, and electrons.'},
            {'q': 'Select animals that are mammals:', 'opts': ['Whale', 'Bat', 'Shark', 'Eagle'], 'correct': [0, 1], 'exp': 'Whales and bats are mammals; sharks are fish; eagles are birds.'},
            {'q': 'Which are greenhouse gases?', 'opts': ['Carbon dioxide', 'Methane', 'Oxygen', 'Nitrogen'], 'correct': [0, 1], 'exp': 'CO₂ and CH₄ are major greenhouse gases.'},
            {'q': 'Select examples of physical changes:', 'opts': ['Melting ice', 'Boiling water', 'Burning wood', 'Rusting iron'], 'correct': [0, 1], 'exp': 'Melting and boiling are physical; burning and rusting are chemical.'},
            {'q': 'Which organs are part of the digestive system?', 'opts': ['Stomach', 'Small intestine', 'Lungs', 'Heart'], 'correct': [0, 1], 'exp': 'Stomach and intestines digest food; lungs and heart are for respiration and circulation.'},
        ],
        'short_answer': [
            {'q': 'How many bones are in the adult human body?', 'answer': '206', 'exp': 'Adults have 206 bones; babies have more which fuse together.'},
            {'q': 'What is the chemical formula for table salt?', 'answer': 'NaCl', 'exp': 'Sodium chloride (table salt) is NaCl.'},
            {'q': 'At what temperature (°C) does water boil at sea level?', 'answer': '100', 'exp': 'Water boils at 100°C (212°F) at standard atmospheric pressure.'},
            {'q': 'How many chromosomes do humans have?', 'answer': '46', 'exp': 'Humans have 23 pairs = 46 chromosomes.'},
            {'q': 'What is the pH of pure water?', 'answer': '7', 'exp': 'Pure water has a neutral pH of 7.'},
            {'q': 'How many planets are in our solar system?', 'answer': '8', 'exp': 'There are 8 planets (Pluto is a dwarf planet).'},
            {'q': 'What percentage of Earth\'s atmosphere is Nitrogen?', 'answer': '78', 'exp': 'Nitrogen makes up about 78% of Earth\'s atmosphere.'},
            {'q': 'What is the freezing point of water in Celsius?', 'answer': '0', 'exp': 'Water freezes at 0°C (32°F).'},
        ],
        'rearrange': [
            {'q': 'Arrange the planets from Sun (closest to farthest): Mars, Venus, Earth, Mercury', 'opts': ['Mercury', 'Venus', 'Earth', 'Mars'], 'correct_order': [0, 1, 2, 3], 'exp': 'Order from Sun: Mercury, Venus, Earth, Mars'},
            {'q': 'Arrange the food chain correctly', 'opts': ['Sun', 'Grass', 'Grasshopper', 'Frog'], 'correct_order': [0, 1, 2, 3], 'exp': 'Sun → Producer (Grass) → Primary consumer → Secondary consumer'},
            {'q': 'Arrange the water cycle steps', 'opts': ['Evaporation', 'Condensation', 'Precipitation', 'Collection'], 'correct_order': [0, 1, 2, 3], 'exp': 'Water cycle: Evaporation → Condensation → Precipitation → Collection'},
            {'q': 'Arrange in order of increasing size: Cell, Atom, Molecule, Organ', 'opts': ['Atom', 'Molecule', 'Cell', 'Organ'], 'correct_order': [0, 1, 2, 3], 'exp': 'Size order: Atom < Molecule < Cell < Organ'},
            {'q': 'Arrange the layers of Earth from inside to outside', 'opts': ['Inner core', 'Outer core', 'Mantle', 'Crust'], 'correct_order': [0, 1, 2, 3], 'exp': 'Earth layers: Inner core → Outer core → Mantle → Crust'},
            {'q': 'Arrange stages of mitosis in order', 'opts': ['Prophase', 'Metaphase', 'Anaphase', 'Telophase'], 'correct_order': [0, 1, 2, 3], 'exp': 'Mitosis: Prophase → Metaphase → Anaphase → Telophase'},
            {'q': 'Arrange electromagnetic waves by increasing frequency', 'opts': ['Radio waves', 'Microwaves', 'Visible light', 'X-rays'], 'correct_order': [0, 1, 2, 3], 'exp': 'Frequency increases: Radio < Microwave < Visible < X-ray'},
            {'q': 'Arrange the digestive process steps', 'opts': ['Ingestion', 'Digestion', 'Absorption', 'Excretion'], 'correct_order': [0, 1, 2, 3], 'exp': 'Digestion: Ingestion → Digestion → Absorption → Excretion'},
        ],
    },
    'English': {
        'mcq_single': [
            {'q': 'What is the past tense of "go"?', 'opts': ['Went', 'Gone', 'Going', 'Goed'], 'correct': 0, 'exp': 'The past tense of "go" is "went".'},
            {'q': 'Which is a noun in the sentence: "The cat sleeps on the mat."?', 'opts': ['Cat', 'Sleeps', 'On', 'The'], 'correct': 0, 'exp': 'Cat is a noun (person, place, thing, or idea).'},
            {'q': 'What is the plural of "child"?', 'opts': ['Children', 'Childs', 'Childes', 'Childrens'], 'correct': 0, 'exp': 'Child is an irregular noun; its plural is children.'},
            {'q': 'Which word is an adverb?', 'opts': ['Quickly', 'Quick', 'Quickness', 'Quicken'], 'correct': 0, 'exp': 'Quickly modifies verbs and is an adverb.'},
            {'q': 'What is the opposite of "ancient"?', 'opts': ['Modern', 'Old', 'Historic', 'Antique'], 'correct': 0, 'exp': 'Ancient means very old; modern means new or current.'},
            {'q': 'Which sentence is grammatically correct?', 'opts': ['She has gone to school.', 'She have gone to school.', 'She has went to school.', 'She have went to school.'], 'correct': 0, 'exp': 'Correct: has + past participle (gone).'},
            {'q': 'What is the comparative form of "good"?', 'opts': ['Better', 'Gooder', 'More good', 'Best'], 'correct': 0, 'exp': 'Good is irregular: good → better → best.'},
            {'q': 'Which is a conjunction?', 'opts': ['And', 'Run', 'Happy', 'Quick'], 'correct': 0, 'exp': 'And joins words or clauses and is a conjunction.'},
        ],
        'mcq_multiple': [
            {'q': 'Select all pronouns:', 'opts': ['He', 'They', 'Running', 'Beautiful'], 'correct': [0, 1], 'exp': 'He and They are pronouns; Running is a verb; Beautiful is an adjective.'},
            {'q': 'Which are prepositions?', 'opts': ['In', 'Under', 'Jump', 'Happy'], 'correct': [0, 1], 'exp': 'In and Under show position and are prepositions.'},
            {'q': 'Select all adjectives:', 'opts': ['Beautiful', 'Tall', 'Run', 'Speak'], 'correct': [0, 1], 'exp': 'Beautiful and Tall describe nouns and are adjectives.'},
            {'q': 'Which words are homophones?', 'opts': ['Their', 'There', 'The', 'Then'], 'correct': [0, 1], 'exp': 'Their and There sound the same but have different meanings.'},
            {'q': 'Select all articles:', 'opts': ['The', 'A', 'Is', 'At'], 'correct': [0, 1], 'exp': 'The, a, and an are articles.'},
            {'q': 'Which are examples of alliteration?', 'opts': ['Peter Piper picked', 'She sells seashells', 'The cat sat', 'I went home'], 'correct': [0, 1], 'exp': 'Alliteration repeats initial consonant sounds.'},
            {'q': 'Select all irregular verbs:', 'opts': ['Go', 'Eat', 'Walk', 'Play'], 'correct': [0, 1], 'exp': 'Go and Eat have irregular past tenses (went, ate).'},
            {'q': 'Which sentences are in passive voice?', 'opts': ['The cake was eaten.', 'The ball was thrown.', 'She ate cake.', 'He threw the ball.'], 'correct': [0, 1], 'exp': 'Passive: subject receives action (was eaten, was thrown).'},
        ],
        'short_answer': [
            {'q': 'What is the past participle of "write"?', 'answer': 'Written', 'exp': 'Write → Wrote → Written'},
            {'q': 'Name the figure of speech: "The wind whispered."', 'answer': 'Personification', 'exp': 'Giving human qualities (whispering) to non-human things is personification.'},
            {'q': 'What is the plural of "mouse"?', 'answer': 'Mice', 'exp': 'Mouse is irregular; plural is mice.'},
            {'q': 'What punctuation ends a question?', 'answer': 'Question mark', 'exp': 'Questions end with a question mark (?).'},
            {'q': 'What type of sentence expresses strong emotion?', 'answer': 'Exclamatory', 'exp': 'Exclamatory sentences show strong feeling and end with !'},
            {'q': 'What is a word that means the same as another word called?', 'answer': 'Synonym', 'exp': 'Synonyms are words with similar meanings.'},
            {'q': 'How many syllables are in the word "beautiful"?', 'answer': '3', 'exp': 'Beau-ti-ful has 3 syllables.'},
            {'q': 'What is the opposite of a synonym called?', 'answer': 'Antonym', 'exp': 'Antonyms are words with opposite meanings.'},
        ],
        'rearrange': [
            {'q': 'Arrange to form a correct sentence: "school / to / go / I / every day"', 'opts': ['I', 'go', 'to', 'school every day'], 'correct_order': [0, 1, 2, 3], 'exp': 'Correct: I go to school every day.'},
            {'q': 'Arrange in alphabetical order: Dog, Cat, Ant, Bear', 'opts': ['Ant', 'Bear', 'Cat', 'Dog'], 'correct_order': [0, 1, 2, 3], 'exp': 'Alphabetical: Ant, Bear, Cat, Dog'},
            {'q': 'Arrange the story elements in order', 'opts': ['Beginning', 'Rising Action', 'Climax', 'Resolution'], 'correct_order': [0, 1, 2, 3], 'exp': 'Story structure: Beginning → Rising Action → Climax → Resolution'},
            {'q': 'Arrange to form a question: "name / is / what / your"', 'opts': ['What', 'is', 'your', 'name'], 'correct_order': [0, 1, 2, 3], 'exp': 'Correct: What is your name?'},
            {'q': 'Arrange the steps of the writing process', 'opts': ['Prewriting', 'Drafting', 'Revising', 'Publishing'], 'correct_order': [0, 1, 2, 3], 'exp': 'Writing process: Prewriting → Drafting → Revising → Publishing'},
            {'q': 'Arrange in order of length (shortest to longest): Word, Sentence, Paragraph, Essay', 'opts': ['Word', 'Sentence', 'Paragraph', 'Essay'], 'correct_order': [0, 1, 2, 3], 'exp': 'Word < Sentence < Paragraph < Essay'},
            {'q': 'Arrange: "quickly / ran / the / rabbit"', 'opts': ['The', 'rabbit', 'ran', 'quickly'], 'correct_order': [0, 1, 2, 3], 'exp': 'Correct: The rabbit ran quickly.'},
            {'q': 'Arrange tenses in timeline order', 'opts': ['Past', 'Present', 'Future', 'Future Perfect'], 'correct_order': [0, 1, 2, 3], 'exp': 'Timeline: Past → Present → Future → Future Perfect'},
        ],
    },
    'History': {
        'mcq_single': [
            {'q': 'When did World War II end?', 'opts': ['1945', '1944', '1946', '1943'], 'correct': 0, 'exp': 'WWII ended in 1945 with the surrender of Japan.'},
            {'q': 'Who was the first President of the United States?', 'opts': ['George Washington', 'Abraham Lincoln', 'Thomas Jefferson', 'John Adams'], 'correct': 0, 'exp': 'George Washington served as the first US President (1789-1797).'},
            {'q': 'In which year did India gain independence?', 'opts': ['1947', '1950', '1942', '1945'], 'correct': 0, 'exp': 'India became independent on August 15, 1947.'},
            {'q': 'Which ancient civilization built the pyramids?', 'opts': ['Egyptian', 'Roman', 'Greek', 'Mesopotamian'], 'correct': 0, 'exp': 'Ancient Egyptians built the pyramids as tombs for pharaohs.'},
            {'q': 'The French Revolution began in which year?', 'opts': ['1789', '1776', '1799', '1804'], 'correct': 0, 'exp': 'The French Revolution began in 1789 with the storming of the Bastille.'},
            {'q': 'Who discovered America in 1492?', 'opts': ['Christopher Columbus', 'Amerigo Vespucci', 'Ferdinand Magellan', 'Vasco da Gama'], 'correct': 0, 'exp': 'Columbus reached the Americas in 1492, though Vikings came earlier.'},
            {'q': 'The Industrial Revolution started in which country?', 'opts': ['Britain', 'France', 'Germany', 'USA'], 'correct': 0, 'exp': 'The Industrial Revolution began in Britain in the mid-18th century.'},
            {'q': 'Who was known as the "Father of the Nation" in India?', 'opts': ['Mahatma Gandhi', 'Jawaharlal Nehru', 'Subhas Chandra Bose', 'Sardar Patel'], 'correct': 0, 'exp': 'Mahatma Gandhi is called the Father of the Nation for his role in independence.'},
        ],
        'mcq_multiple': [
            {'q': 'Which countries were Axis Powers in WWII?', 'opts': ['Germany', 'Japan', 'Britain', 'France'], 'correct': [0, 1], 'exp': 'Germany, Japan, and Italy were the main Axis Powers.'},
            {'q': 'Select all ancient civilizations:', 'opts': ['Indus Valley', 'Egyptian', 'American', 'British'], 'correct': [0, 1], 'exp': 'Indus Valley and Egyptian were ancient civilizations.'},
            {'q': 'Which were causes of World War I?', 'opts': ['Militarism', 'Alliances', 'Social media', 'Internet'], 'correct': [0, 1], 'exp': 'MAIN causes: Militarism, Alliances, Imperialism, Nationalism.'},
            {'q': 'Select leaders of the Indian Independence Movement:', 'opts': ['Gandhi', 'Nehru', 'Churchill', 'Hitler'], 'correct': [0, 1], 'exp': 'Gandhi and Nehru led India\'s independence movement.'},
            {'q': 'Which empires existed in ancient times?', 'opts': ['Roman Empire', 'Maurya Empire', 'British Empire', 'Soviet Union'], 'correct': [0, 1], 'exp': 'Roman and Maurya were ancient; British and Soviet were modern.'},
            {'q': 'Select Renaissance artists:', 'opts': ['Leonardo da Vinci', 'Michelangelo', 'Picasso', 'Van Gogh'], 'correct': [0, 1], 'exp': 'Da Vinci and Michelangelo were Renaissance artists.'},
            {'q': 'Which were Allied Powers in WWII?', 'opts': ['USA', 'Britain', 'Germany', 'Japan'], 'correct': [0, 1], 'exp': 'USA, Britain, France, and USSR were Allied Powers.'},
            {'q': 'Select ancient wonders of the world:', 'opts': ['Pyramids of Giza', 'Hanging Gardens of Babylon', 'Eiffel Tower', 'Statue of Liberty'], 'correct': [0, 1], 'exp': 'Pyramids and Hanging Gardens were ancient wonders.'},
        ],
        'short_answer': [
            {'q': 'In which year did the Berlin Wall fall?', 'answer': '1989', 'exp': 'The Berlin Wall fell on November 9, 1989.'},
            {'q': 'Who was the first Emperor of unified China?', 'answer': 'Qin Shi Huang', 'exp': 'Qin Shi Huang unified China in 221 BCE.'},
            {'q': 'How many years did World War I last?', 'answer': '4', 'exp': 'WWI lasted from 1914 to 1918 (4 years).'},
            {'q': 'In which century did the Renaissance begin?', 'answer': '14', 'exp': 'The Renaissance began in the 14th century in Italy.'},
            {'q': 'What was the name of the ship on which Pilgrims sailed to America?', 'answer': 'Mayflower', 'exp': 'The Mayflower brought Pilgrims to Plymouth in 1620.'},
            {'q': 'Who invented the printing press?', 'answer': 'Gutenberg', 'exp': 'Johannes Gutenberg invented the printing press around 1440.'},
            {'q': 'In which year was the United Nations founded?', 'answer': '1945', 'exp': 'The UN was founded in 1945 after WWII.'},
            {'q': 'How many years did the Hundred Years\' War actually last?', 'answer': '116', 'exp': 'The Hundred Years\' War lasted from 1337 to 1453 (116 years).'},
        ],
        'rearrange': [
            {'q': 'Arrange these events in chronological order', 'opts': ['Ancient Egypt', 'Roman Empire', 'Medieval Period', 'Renaissance'], 'correct_order': [0, 1, 2, 3], 'exp': 'Timeline: Ancient Egypt → Rome → Medieval → Renaissance'},
            {'q': 'Arrange Indian history events in order', 'opts': ['Indus Valley Civilization', 'Maurya Empire', 'Mughal Empire', 'British Rule'], 'correct_order': [0, 1, 2, 3], 'exp': 'Indian history: Indus Valley → Maurya → Mughal → British'},
            {'q': 'Arrange these inventions by date', 'opts': ['Wheel', 'Printing Press', 'Steam Engine', 'Internet'], 'correct_order': [0, 1, 2, 3], 'exp': 'Inventions: Wheel (ancient) → Printing → Steam → Internet'},
            {'q': 'Arrange US Presidents in order', 'opts': ['Washington', 'Lincoln', 'Roosevelt', 'Kennedy'], 'correct_order': [0, 1, 2, 3], 'exp': 'Presidents: Washington → Lincoln → Roosevelt → Kennedy'},
            {'q': 'Arrange world wars and events', 'opts': ['WWI begins', 'WWI ends', 'WWII begins', 'WWII ends'], 'correct_order': [0, 1, 2, 3], 'exp': '1914 → 1918 → 1939 → 1945'},
            {'q': 'Arrange ancient civilizations by origin', 'opts': ['Mesopotamia', 'Egypt', 'Indus Valley', 'China'], 'correct_order': [0, 1, 2, 3], 'exp': 'Approximate order of emergence of major civilizations'},
            {'q': 'Arrange periods of European history', 'opts': ['Ancient', 'Medieval', 'Modern', 'Contemporary'], 'correct_order': [0, 1, 2, 3], 'exp': 'Historical periods in chronological order'},
            {'q': 'Arrange space exploration milestones', 'opts': ['First satellite', 'First human in space', 'Moon landing', 'Mars rover'], 'correct_order': [0, 1, 2, 3], 'exp': 'Sputnik 1957 → Gagarin 1961 → Moon 1969 → Mars rovers 2000s'},
        ],
    },
    'Economics': {
        'mcq_single': [
            {'q': 'What is GDP?', 'opts': ['Gross Domestic Product', 'General Domestic Price', 'Growth Development Plan', 'Government Debt Payment'], 'correct': 0, 'exp': 'GDP measures the total value of goods and services produced in a country.'},
            {'q': 'What happens when supply exceeds demand?', 'opts': ['Prices decrease', 'Prices increase', 'Prices stay same', 'Market closes'], 'correct': 0, 'exp': 'Excess supply leads to lower prices as sellers compete.'},
            {'q': 'What is inflation?', 'opts': ['Rise in general price levels', 'Fall in prices', 'Increase in money supply', 'Economic growth'], 'correct': 0, 'exp': 'Inflation is the sustained increase in general price levels.'},
            {'q': 'Which is an example of a public good?', 'opts': ['Street lighting', 'Private car', 'Personal computer', 'House'], 'correct': 0, 'exp': 'Public goods are non-excludable and non-rivalrous.'},
            {'q': 'What is the main function of a central bank?', 'opts': ['Control monetary policy', 'Sell products', 'Manufacture goods', 'Provide loans to individuals'], 'correct': 0, 'exp': 'Central banks manage money supply and interest rates.'},
            {'q': 'What is opportunity cost?', 'opts': ['Value of next best alternative forgone', 'Price of a product', 'Cost of production', 'Market price'], 'correct': 0, 'exp': 'Opportunity cost is what you give up when making a choice.'},
            {'q': 'Which sector includes agriculture?', 'opts': ['Primary', 'Secondary', 'Tertiary', 'Quaternary'], 'correct': 0, 'exp': 'Primary sector involves extraction of raw materials like farming.'},
            {'q': 'What is a monopoly?', 'opts': ['Single seller in market', 'Many sellers', 'Few sellers', 'No sellers'], 'correct': 0, 'exp': 'A monopoly exists when one firm dominates the entire market.'},
        ],
        'mcq_multiple': [
            {'q': 'Which are factors of production?', 'opts': ['Land', 'Labor', 'Profit', 'Tax'], 'correct': [0, 1], 'exp': 'Factors of production: Land, Labor, Capital, Enterprise.'},
            {'q': 'Select examples of indirect taxes:', 'opts': ['GST', 'Sales tax', 'Income tax', 'Property tax'], 'correct': [0, 1], 'exp': 'GST and sales tax are indirect; income tax is direct.'},
            {'q': 'Which are functions of money?', 'opts': ['Medium of exchange', 'Store of value', 'Source of energy', 'Building material'], 'correct': [0, 1], 'exp': 'Money functions: Exchange medium, store of value, unit of account.'},
            {'q': 'Select types of unemployment:', 'opts': ['Structural', 'Cyclical', 'Financial', 'Material'], 'correct': [0, 1], 'exp': 'Types include structural, cyclical, frictional, seasonal.'},
            {'q': 'Which are examples of natural resources?', 'opts': ['Water', 'Minerals', 'Machines', 'Buildings'], 'correct': [0, 1], 'exp': 'Natural resources are provided by nature, not man-made.'},
            {'q': 'Select characteristics of perfect competition:', 'opts': ['Many buyers and sellers', 'Homogeneous products', 'Single seller', 'High barriers'], 'correct': [0, 1], 'exp': 'Perfect competition has many firms selling identical products.'},
            {'q': 'Which are parts of fiscal policy?', 'opts': ['Government spending', 'Taxation', 'Interest rates', 'Money supply'], 'correct': [0, 1], 'exp': 'Fiscal policy uses spending and taxation; monetary policy uses interest rates.'},
            {'q': 'Select examples of services:', 'opts': ['Education', 'Healthcare', 'Car', 'Phone'], 'correct': [0, 1], 'exp': 'Services are intangible; cars and phones are goods.'},
        ],
        'short_answer': [
            {'q': 'What does "GDP" stand for?', 'answer': 'Gross Domestic Product', 'exp': 'GDP measures a nation\'s total economic output.'},
            {'q': 'What is the basic economic problem?', 'answer': 'Scarcity', 'exp': 'Scarcity: unlimited wants but limited resources.'},
            {'q': 'Name the economic system where government controls production', 'answer': 'Socialism', 'exp': 'In socialism/command economy, government controls resources.'},
            {'q': 'What term describes a continuous fall in prices?', 'answer': 'Deflation', 'exp': 'Deflation is the opposite of inflation.'},
            {'q': 'What is the study of individual economic units called?', 'answer': 'Microeconomics', 'exp': 'Microeconomics studies individuals, firms, and markets.'},
            {'q': 'Name the graph showing income distribution inequality', 'answer': 'Lorenz curve', 'exp': 'The Lorenz curve shows wealth/income distribution.'},
            {'q': 'What currency is used in the European Union?', 'answer': 'Euro', 'exp': 'The Euro (€) is used by most EU countries.'},
            {'q': 'What organization regulates international trade?', 'answer': 'WTO', 'exp': 'World Trade Organization regulates global trade.'},
        ],
        'rearrange': [
            {'q': 'Arrange the economic development stages', 'opts': ['Agricultural', 'Industrial', 'Service', 'Knowledge'], 'correct_order': [0, 1, 2, 3], 'exp': 'Economies progress from agriculture to knowledge-based.'},
            {'q': 'Arrange by market structure (least to most competition)', 'opts': ['Monopoly', 'Oligopoly', 'Monopolistic', 'Perfect competition'], 'correct_order': [0, 1, 2, 3], 'exp': 'Competition increases from monopoly to perfect competition.'},
            {'q': 'Arrange the business cycle phases', 'opts': ['Expansion', 'Peak', 'Recession', 'Trough'], 'correct_order': [0, 1, 2, 3], 'exp': 'Business cycle: Expansion → Peak → Recession → Trough'},
            {'q': 'Arrange from least to most liquid assets', 'opts': ['Real estate', 'Gold', 'Savings account', 'Cash'], 'correct_order': [0, 1, 2, 3], 'exp': 'Liquidity: Real estate < Gold < Savings < Cash'},
            {'q': 'Arrange the production process', 'opts': ['Raw materials', 'Processing', 'Finished goods', 'Distribution'], 'correct_order': [0, 1, 2, 3], 'exp': 'Production: Raw materials → Processing → Goods → Distribution'},
            {'q': 'Arrange economic systems by government control', 'opts': ['Capitalism', 'Mixed economy', 'Socialism', 'Communism'], 'correct_order': [0, 1, 2, 3], 'exp': 'Government control increases: Capitalism → Communism'},
            {'q': 'Arrange the decision-making process', 'opts': ['Identify problem', 'Gather information', 'Evaluate options', 'Make decision'], 'correct_order': [0, 1, 2, 3], 'exp': 'Decision process: Problem → Info → Evaluate → Decide'},
            {'q': 'Arrange by GDP (typical order for developing nations)', 'opts': ['Primary sector dominant', 'Secondary sector growth', 'Tertiary sector rise', 'Quaternary focus'], 'correct_order': [0, 1, 2, 3], 'exp': 'Development: Primary → Secondary → Tertiary → Quaternary'},
        ],
    },
    'Civics': {
        'mcq_single': [
            {'q': 'What is democracy?', 'opts': ['Government by the people', 'Rule by one person', 'Military rule', 'Religious rule'], 'correct': 0, 'exp': 'Democracy means government of, by, and for the people.'},
            {'q': 'What is the minimum voting age in India?', 'opts': ['18', '21', '16', '25'], 'correct': 0, 'exp': 'The voting age in India is 18 years.'},
            {'q': 'Who is the head of state in India?', 'opts': ['President', 'Prime Minister', 'Chief Justice', 'Speaker'], 'correct': 0, 'exp': 'The President is the constitutional head of state.'},
            {'q': 'What is the supreme law of India?', 'opts': ['Constitution', 'Parliament Act', 'Supreme Court Order', 'President Order'], 'correct': 0, 'exp': 'The Constitution is the supreme law of the land.'},
            {'q': 'How many Fundamental Rights are there in Indian Constitution?', 'opts': ['6', '7', '5', '8'], 'correct': 0, 'exp': 'There are 6 Fundamental Rights (Right to Property was removed).'},
            {'q': 'What is the term of Lok Sabha?', 'opts': ['5 years', '6 years', '4 years', '7 years'], 'correct': 0, 'exp': 'Lok Sabha has a term of 5 years unless dissolved earlier.'},
            {'q': 'Who appoints the Chief Justice of India?', 'opts': ['President', 'Prime Minister', 'Law Minister', 'Parliament'], 'correct': 0, 'exp': 'The President appoints the CJI on recommendation of collegium.'},
            {'q': 'What is secularism?', 'opts': ['Separation of religion from state', 'Religious state', 'Atheistic state', 'Theocracy'], 'correct': 0, 'exp': 'Secularism means the state treats all religions equally.'},
        ],
        'mcq_multiple': [
            {'q': 'Which are Fundamental Rights in India?', 'opts': ['Right to Equality', 'Right to Freedom', 'Right to Property', 'Right to Vote'], 'correct': [0, 1], 'exp': 'Right to Property was removed; Right to Vote is constitutional right.'},
            {'q': 'Select features of democracy:', 'opts': ['Free elections', 'Rule of law', 'Military control', 'Single party'], 'correct': [0, 1], 'exp': 'Democracy features: Elections, rule of law, multiple parties.'},
            {'q': 'Which are organs of government?', 'opts': ['Legislature', 'Executive', 'Media', 'NGO'], 'correct': [0, 1], 'exp': 'Three organs: Legislature, Executive, Judiciary.'},
            {'q': 'Select types of government:', 'opts': ['Federal', 'Unitary', 'Corporate', 'NGO'], 'correct': [0, 1], 'exp': 'Federal and Unitary are types of government systems.'},
            {'q': 'Which are duties of citizens?', 'opts': ['Paying taxes', 'Voting', 'Making laws', 'Appointing ministers'], 'correct': [0, 1], 'exp': 'Citizens should pay taxes and vote; lawmakers make laws.'},
            {'q': 'Select parts of Indian Parliament:', 'opts': ['Lok Sabha', 'Rajya Sabha', 'Vidhan Sabha', 'Municipal Council'], 'correct': [0, 1], 'exp': 'Parliament = President + Lok Sabha + Rajya Sabha.'},
            {'q': 'Which are directive principles?', 'opts': ['Equal pay for equal work', 'Free education', 'Right to strike', 'Right to property'], 'correct': [0, 1], 'exp': 'DPSPs guide state policy but are not enforceable.'},
            {'q': 'Select levels of government in India:', 'opts': ['Central', 'State', 'Corporate', 'Private'], 'correct': [0, 1], 'exp': 'Three levels: Central, State, Local government.'},
        ],
        'short_answer': [
            {'q': 'What is the Preamble?', 'answer': 'Introduction to Constitution', 'exp': 'The Preamble is the introduction stating the ideals of the Constitution.'},
            {'q': 'How many states are there in India (as of 2023)?', 'answer': '28', 'exp': 'India has 28 states and 8 Union Territories.'},
            {'q': 'What is the national animal of India?', 'answer': 'Tiger', 'exp': 'The Bengal Tiger is India\'s national animal.'},
            {'q': 'Who wrote the Indian Constitution?', 'answer': 'Dr B R Ambedkar', 'exp': 'Dr. Ambedkar was the chief architect of the Constitution.'},
            {'q': 'When is Republic Day celebrated?', 'answer': '26 January', 'exp': 'Republic Day marks the adoption of the Constitution on January 26, 1950.'},
            {'q': 'What is the national emblem of India adapted from?', 'answer': 'Ashoka Pillar', 'exp': 'The Lion Capital of Ashoka at Sarnath is the national emblem.'},
            {'q': 'How many members are in Rajya Sabha?', 'answer': '250', 'exp': 'Rajya Sabha has a maximum of 250 members.'},
            {'q': 'What is the motto of India (in Sanskrit)?', 'answer': 'Satyameva Jayate', 'exp': 'Satyameva Jayate means "Truth Alone Triumphs".'},
        ],
        'rearrange': [
            {'q': 'Arrange the levels of government (top to bottom)', 'opts': ['Central', 'State', 'District', 'Local'], 'correct_order': [0, 1, 2, 3], 'exp': 'Hierarchy: Central → State → District → Local'},
            {'q': 'Arrange the law-making process', 'opts': ['Bill introduced', 'Committee review', 'Voting', 'President assent'], 'correct_order': [0, 1, 2, 3], 'exp': 'Law: Introduction → Committee → Voting → Assent'},
            {'q': 'Arrange the election process', 'opts': ['Nomination', 'Campaigning', 'Voting', 'Counting'], 'correct_order': [0, 1, 2, 3], 'exp': 'Election: Nomination → Campaign → Vote → Count'},
            {'q': 'Arrange the judicial hierarchy', 'opts': ['Lower courts', 'District courts', 'High courts', 'Supreme Court'], 'correct_order': [0, 1, 2, 3], 'exp': 'Judicial hierarchy from lowest to highest'},
            {'q': 'Arrange the constitutional amendment process', 'opts': ['Bill introduction', 'Special majority vote', 'State ratification (if needed)', 'Presidential assent'], 'correct_order': [0, 1, 2, 3], 'exp': 'Amendment: Bill → Vote → State approval → Assent'},
            {'q': 'Arrange the parts of Constitution', 'opts': ['Preamble', 'Fundamental Rights', 'DPSPs', 'Amendments'], 'correct_order': [0, 1, 2, 3], 'exp': 'Constitution structure: Preamble first, amendments at end'},
            {'q': 'Arrange the citizenship acquisition methods', 'opts': ['By birth', 'By descent', 'By registration', 'By naturalization'], 'correct_order': [0, 1, 2, 3], 'exp': 'Ways to become a citizen in order of complexity'},
            {'q': 'Arrange the emergency provisions by severity', 'opts': ['State emergency', 'Financial emergency', 'President rule', 'National emergency'], 'correct_order': [0, 1, 2, 3], 'exp': 'Different types of emergencies in the Constitution'},
        ],
    },
}


def get_default_questions(subject_name, question_type):
    """Generate default questions if subject-specific ones don't exist."""
    questions = []
    
    if question_type == 'mcq_single':
        for i in range(8):
            questions.append({
                'q': f'{subject_name} MCQ Single Question {i+1}',
                'opts': [f'Correct Answer', f'Wrong A', f'Wrong B', f'Wrong C'],
                'correct': 0,
                'exp': f'Explanation for {subject_name} MCQ {i+1}'
            })
    elif question_type == 'mcq_multiple':
        for i in range(8):
            questions.append({
                'q': f'{subject_name} MCQ Multiple Question {i+1}',
                'opts': [f'Correct 1', f'Correct 2', f'Wrong A', f'Wrong B'],
                'correct': [0, 1],
                'exp': f'Explanation for {subject_name} MCQ Multiple {i+1}'
            })
    elif question_type == 'short_answer':
        for i in range(8):
            questions.append({
                'q': f'{subject_name} Short Answer Question {i+1}',
                'answer': 'Answer',
                'exp': f'Explanation for {subject_name} Short Answer {i+1}'
            })
    elif question_type == 'rearrange':
        for i in range(8):
            questions.append({
                'q': f'{subject_name} Rearrange Question {i+1}',
                'opts': ['First', 'Second', 'Third', 'Fourth'],
                'correct_order': [0, 1, 2, 3],
                'exp': f'Explanation for {subject_name} Rearrange {i+1}'
            })
    
    return questions


class Command(BaseCommand):
    help = 'Create missions for all subjects with 4 questions of each type for today and tomorrow'

    def add_arguments(self, parser):
        parser.add_argument(
            '--clear-existing',
            action='store_true',
            help='Delete all existing missions before creating new ones',
        )

    def handle(self, *args, **options):
        clear_existing = options.get('clear_existing', False)
        
        today = timezone.now().date()
        tomorrow = today + timedelta(days=1)
        
        self.stdout.write(f'\nCreating missions for:')
        self.stdout.write(f'  Today: {today}')
        self.stdout.write(f'  Tomorrow: {tomorrow}')
        
        school, created = School.objects.get_or_create(
            name='Default School',
            defaults={
                'address': 'Default Address',
                'phone': '1234567890',
                'email': 'school@example.com',
                'is_active': True
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'Created school: {school.name}'))
        
        class_obj, created = Class.objects.get_or_create(
            name='Class 9A',
            school=school,
            defaults={
                'description': 'Class 9 Section A',
                'is_active': True
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'Created class: {class_obj.name}'))
        
        created_by = Account.objects.filter(is_superuser=True).first()
        if not created_by:
            created_by = Account.objects.first()
        
        if clear_existing:
            self.stdout.write('Deleting existing missions...')
            Mission.objects.filter(mission_date__in=[today, tomorrow]).delete()
            self.stdout.write(self.style.SUCCESS('Existing missions deleted.'))
        
        subjects = Subject.objects.filter(is_active=True)
        
        if not subjects.exists():
            self.stdout.write(self.style.WARNING('No subjects found. Creating default subjects...'))
            default_subjects = ['Math', 'Science', 'English', 'History', 'Economics', 'Civics']
            for i, subj_name in enumerate(default_subjects):
                Subject.objects.get_or_create(
                    name=subj_name,
                    defaults={
                        'code': subj_name[:3].upper(),
                        'description': f'{subj_name} subject',
                        'is_active': True,
                        'order': i + 1
                    }
                )
            subjects = Subject.objects.filter(is_active=True)
        
        stats = {
            'missions': 0,
            'questions': 0,
            'mission_questions': 0
        }
        
        question_types = ['mcq_single', 'mcq_multiple', 'short_answer', 'rearrange']
        
        with transaction.atomic():
            for subject in subjects:
                self.stdout.write(f'\nProcessing subject: {subject.name}')
                
                if subject not in class_obj.subjects.all():
                    class_obj.subjects.add(subject)
                
                subject_questions = MISSION_QUESTIONS.get(subject.name, {})
                
                for mission_date in [today, tomorrow]:
                    date_str = 'Today' if mission_date == today else 'Tomorrow'
                    
                    existing_mission = Mission.objects.filter(
                        subject=subject,
                        class_group=class_obj,
                        mission_date=mission_date,
                        is_deleted=False
                    ).first()
                    
                    if existing_mission:
                        self.stdout.write(f'  Mission for {date_str} already exists, skipping...')
                        continue
                    
                    mission = Mission.objects.create(
                        title=f'{subject.name} Daily Mission - {mission_date.strftime("%d %B %Y")}',
                        description=f'Complete this {subject.name} mission to earn experience points!',
                        mission_date=mission_date,
                        exp_multiplier=1.5,
                        base_exp=100,
                        duration=30,
                        is_active=True,
                        created_by=created_by,
                        class_group=class_obj,
                        subject=subject
                    )
                    stats['missions'] += 1
                    
                    question_order = 1
                    
                    for q_type in question_types:
                        if q_type in subject_questions:
                            type_questions = subject_questions[q_type]
                        else:
                            type_questions = get_default_questions(subject.name, q_type)
                        
                        if mission_date == tomorrow:
                            type_questions = type_questions[4:8] if len(type_questions) > 4 else type_questions[:4]
                        else:
                            type_questions = type_questions[:4]
                        
                        for q_data in type_questions:
                            question = Question.objects.create(
                                question_text=q_data['q'],
                                question_type=q_type,
                                exp_points=random.randint(10, 25),
                                difficulty_level=random.choice(['easy', 'medium', 'hard']),
                                explanation=q_data.get('exp', ''),
                                is_active=True,
                                is_hots=False,
                                created_by=created_by
                            )
                            stats['questions'] += 1
                            
                            if q_type == 'mcq_single':
                                for opt_order, opt_text in enumerate(q_data['opts'], start=1):
                                    Option.objects.create(
                                        question=question,
                                        option_text=opt_text,
                                        is_correct=(opt_order - 1 == q_data['correct']),
                                        order=opt_order
                                    )
                            elif q_type == 'mcq_multiple':
                                for opt_order, opt_text in enumerate(q_data['opts'], start=1):
                                    Option.objects.create(
                                        question=question,
                                        option_text=opt_text,
                                        is_correct=(opt_order - 1 in q_data['correct']),
                                        order=opt_order
                                    )
                            elif q_type == 'short_answer':
                                Option.objects.create(
                                    question=question,
                                    option_text=q_data['answer'],
                                    is_correct=True,
                                    order=1
                                )
                            elif q_type == 'rearrange':
                                for opt_order, opt_text in enumerate(q_data['opts'], start=1):
                                    Option.objects.create(
                                        question=question,
                                        option_text=opt_text,
                                        is_correct=True,
                                        order=opt_order
                                    )
                            
                            MissionQuestion.objects.create(
                                mission=mission,
                                question=question,
                                order=question_order
                            )
                            stats['mission_questions'] += 1
                            question_order += 1
                    
                    self.stdout.write(f'  ✓ Created mission for {date_str} with {question_order - 1} questions')
        
        self.stdout.write('\n' + '=' * 70)
        self.stdout.write(self.style.SUCCESS('SUCCESS! Missions created:'))
        self.stdout.write('=' * 70)
        self.stdout.write(f'  Missions: {stats["missions"]}')
        self.stdout.write(f'  Questions: {stats["questions"]}')
        self.stdout.write(f'  Mission Questions: {stats["mission_questions"]}')
        self.stdout.write('=' * 70)
        self.stdout.write('\nQuestion breakdown per mission:')
        self.stdout.write('  - MCQ Single: 4 questions')
        self.stdout.write('  - MCQ Multiple: 4 questions')
        self.stdout.write('  - Short Answer: 4 questions')
        self.stdout.write('  - Rearrange: 4 questions')
        self.stdout.write('  - Total per mission: 16 questions')
        self.stdout.write('=' * 70)

