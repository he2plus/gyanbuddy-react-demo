"""
Django management command to populate Science subject with:
- 12 modules covering Class 9 Science topics
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

SUBJECT_NAME = 'Science'

SCIENCE_MODULES = {
    'Matter in Our Surroundings': {
        'description': 'Study of matter, its physical nature, and states',
        'chapters': [
            {'title': 'Physical Nature of Matter', 'description': 'Understanding that matter is made of particles'},
            {'title': 'Characteristics of Particles of Matter', 'description': 'Properties of particles'},
            {'title': 'States of Matter', 'description': 'Solid, liquid, and gas states'},
            {'title': 'Change of State of Matter', 'description': 'Melting, freezing, evaporation, condensation'},
            {'title': 'Evaporation', 'description': 'Factors affecting evaporation'},
            {'title': 'Effects of Change of Temperature', 'description': 'How temperature affects matter'},
        ]
    },
    'Is Matter Around Us Pure?': {
        'description': 'Classification of matter into pure substances and mixtures',
        'chapters': [
            {'title': 'What is a Mixture?', 'description': 'Understanding mixtures and their types'},
            {'title': 'Types of Mixtures', 'description': 'Homogeneous and heterogeneous mixtures'},
            {'title': 'Solutions', 'description': 'Properties of solutions'},
            {'title': 'Separation of Mixtures', 'description': 'Various separation techniques'},
            {'title': 'Physical and Chemical Changes', 'description': 'Distinguishing between changes'},
            {'title': 'Compounds and Elements', 'description': 'Pure substances classification'},
        ]
    },
    'Atoms and Molecules': {
        'description': 'Study of atoms, molecules, and chemical formulas',
        'chapters': [
            {'title': 'Laws of Chemical Combination', 'description': 'Law of conservation of mass and definite proportions'},
            {'title': 'What is an Atom?', 'description': 'Dalton\'s atomic theory'},
            {'title': 'What is a Molecule?', 'description': 'Molecules of elements and compounds'},
            {'title': 'Writing Chemical Formulae', 'description': 'Rules for writing formulas'},
            {'title': 'Molecular Mass and Mole Concept', 'description': 'Calculating molecular mass'},
            {'title': 'Mole and Avogadro Number', 'description': 'Understanding the mole concept'},
        ]
    },
    'Structure of the Atom': {
        'description': 'Models of atom and distribution of electrons',
        'chapters': [
            {'title': 'Charged Particles in Matter', 'description': 'Discovery of electrons and protons'},
            {'title': 'Structure of an Atom', 'description': 'Thomson and Rutherford models'},
            {'title': 'Bohr\'s Model of Atom', 'description': 'Energy levels and orbits'},
            {'title': 'Distribution of Electrons', 'description': 'Electronic configuration'},
            {'title': 'Valency', 'description': 'Combining capacity of atoms'},
            {'title': 'Atomic Number and Mass Number', 'description': 'Isotopes and isobars'},
        ]
    },
    'The Fundamental Unit of Life': {
        'description': 'Cell structure and its components',
        'chapters': [
            {'title': 'What is a Cell?', 'description': 'Discovery and types of cells'},
            {'title': 'Structural Organisation of Cell', 'description': 'Cell membrane and cell wall'},
            {'title': 'Nucleus', 'description': 'Structure and function of nucleus'},
            {'title': 'Cytoplasm and Organelles', 'description': 'Cell organelles and their functions'},
            {'title': 'Comparison of Plant and Animal Cells', 'description': 'Differences between cell types'},
            {'title': 'Cell Division', 'description': 'Mitosis and meiosis basics'},
        ]
    },
    'Tissues': {
        'description': 'Study of plant and animal tissues',
        'chapters': [
            {'title': 'Plant Tissues', 'description': 'Meristematic and permanent tissues'},
            {'title': 'Simple Permanent Tissues', 'description': 'Parenchyma, collenchyma, sclerenchyma'},
            {'title': 'Complex Permanent Tissues', 'description': 'Xylem and phloem'},
            {'title': 'Animal Tissues', 'description': 'Types of animal tissues'},
            {'title': 'Epithelial and Connective Tissues', 'description': 'Structure and functions'},
            {'title': 'Muscular and Nervous Tissues', 'description': 'Types and functions'},
        ]
    },
    'Motion': {
        'description': 'Study of motion, speed, velocity, and acceleration',
        'chapters': [
            {'title': 'Describing Motion', 'description': 'Distance, displacement, and reference point'},
            {'title': 'Measuring Rate of Motion', 'description': 'Speed and velocity'},
            {'title': 'Rate of Change of Velocity', 'description': 'Acceleration and its types'},
            {'title': 'Graphical Representation of Motion', 'description': 'Distance-time and velocity-time graphs'},
            {'title': 'Equations of Motion', 'description': 'Derivation and application'},
            {'title': 'Uniform Circular Motion', 'description': 'Motion in a circle'},
        ]
    },
    'Force and Laws of Motion': {
        'description': 'Newton\'s laws of motion and their applications',
        'chapters': [
            {'title': 'Balanced and Unbalanced Forces', 'description': 'Effects of forces'},
            {'title': 'First Law of Motion', 'description': 'Law of inertia'},
            {'title': 'Inertia and Mass', 'description': 'Relationship between inertia and mass'},
            {'title': 'Second Law of Motion', 'description': 'Force, mass, and acceleration'},
            {'title': 'Third Law of Motion', 'description': 'Action and reaction'},
            {'title': 'Conservation of Momentum', 'description': 'Momentum and its conservation'},
        ]
    },
    'Gravitation': {
        'description': 'Universal law of gravitation and motion of objects',
        'chapters': [
            {'title': 'Gravitation', 'description': 'Universal law of gravitation'},
            {'title': 'Free Fall', 'description': 'Motion under gravity'},
            {'title': 'Mass and Weight', 'description': 'Difference between mass and weight'},
            {'title': 'Thrust and Pressure', 'description': 'Pressure in fluids'},
            {'title': 'Archimedes\' Principle', 'description': 'Buoyancy and floating'},
            {'title': 'Relative Density', 'description': 'Comparing densities'},
        ]
    },
    'Work and Energy': {
        'description': 'Work, energy, power, and their relationships',
        'chapters': [
            {'title': 'Work', 'description': 'Scientific definition of work'},
            {'title': 'Energy', 'description': 'Forms and types of energy'},
            {'title': 'Kinetic Energy', 'description': 'Energy of motion'},
            {'title': 'Potential Energy', 'description': 'Stored energy'},
            {'title': 'Law of Conservation of Energy', 'description': 'Energy transformations'},
            {'title': 'Power', 'description': 'Rate of doing work'},
        ]
    },
    'Sound': {
        'description': 'Production, propagation, and characteristics of sound',
        'chapters': [
            {'title': 'Production of Sound', 'description': 'How sound is produced'},
            {'title': 'Propagation of Sound', 'description': 'Sound as a mechanical wave'},
            {'title': 'Characteristics of Sound', 'description': 'Pitch, loudness, and quality'},
            {'title': 'Speed of Sound', 'description': 'Factors affecting speed of sound'},
            {'title': 'Reflection of Sound', 'description': 'Echo and reverberation'},
            {'title': 'Applications of Sound', 'description': 'Ultrasound and sonar'},
        ]
    },
    'Improvement in Food Resources': {
        'description': 'Methods to improve crop and animal production',
        'chapters': [
            {'title': 'Improvement in Crop Yields', 'description': 'Crop variety improvement'},
            {'title': 'Crop Production Management', 'description': 'Nutrient and irrigation management'},
            {'title': 'Crop Protection Management', 'description': 'Protection from pests and diseases'},
            {'title': 'Animal Husbandry', 'description': 'Cattle and poultry farming'},
            {'title': 'Fish Production', 'description': 'Marine and inland fisheries'},
            {'title': 'Bee Keeping', 'description': 'Apiculture and its benefits'},
        ]
    },
}


def get_chapter_questions(module_name, chapter_title):
    """Generate 10 questions for a chapter."""
    questions = []
    
    if module_name == 'Matter in Our Surroundings':
        if chapter_title == 'Physical Nature of Matter':
            questions = [
                {'q': 'Matter is made up of:', 'opts': ['Tiny particles', 'Continuous mass', 'Energy waves', 'Light'], 'correct': 0, 'exp': 'Matter is made up of tiny particles.'},
                {'q': 'Which of the following is NOT a state of matter?', 'opts': ['Energy', 'Solid', 'Liquid', 'Gas'], 'correct': 0, 'exp': 'Energy is not a state of matter.'},
                {'q': 'Particles of matter have:', 'opts': ['Space between them', 'No space between them', 'Fixed positions always', 'No motion'], 'correct': 0, 'exp': 'There are spaces between particles of matter.'},
                {'q': 'The phenomenon of spreading of smell is due to:', 'opts': ['Diffusion', 'Evaporation', 'Condensation', 'Osmosis'], 'correct': 0, 'exp': 'Diffusion is the spreading of particles from higher to lower concentration.'},
                {'q': 'Diffusion is fastest in:', 'opts': ['Gases', 'Liquids', 'Solids', 'Same in all'], 'correct': 0, 'exp': 'Gases have maximum space between particles, so diffusion is fastest.'},
                {'q': 'Particles of matter are:', 'opts': ['Constantly moving', 'Stationary', 'Moving only when heated', 'Not moving'], 'correct': 0, 'exp': 'Particles of matter are constantly moving.'},
                {'q': 'Which shows least diffusion?', 'opts': ['Solids', 'Liquids', 'Gases', 'Plasma'], 'correct': 0, 'exp': 'Solids have least space between particles.'},
                {'q': 'Matter can be classified based on:', 'opts': ['Physical and chemical properties', 'Color only', 'Size only', 'Smell only'], 'correct': 0, 'exp': 'Matter is classified by physical and chemical properties.'},
                {'q': 'When sugar dissolves in water:', 'opts': ['Sugar particles spread uniformly', 'Sugar disappears', 'Sugar becomes water', 'Water evaporates'], 'correct': 0, 'exp': 'Sugar particles spread uniformly among water particles.'},
                {'q': 'The kinetic energy of particles increases with:', 'opts': ['Temperature', 'Pressure', 'Mass', 'Volume'], 'correct': 0, 'exp': 'Higher temperature means more kinetic energy.'},
            ]
        elif chapter_title == 'States of Matter':
            questions = [
                {'q': 'In which state do particles have maximum freedom of movement?', 'opts': ['Gas', 'Solid', 'Liquid', 'All same'], 'correct': 0, 'exp': 'Gas particles have maximum freedom and move randomly.'},
                {'q': 'Which state has definite shape and volume?', 'opts': ['Solid', 'Liquid', 'Gas', 'None'], 'correct': 0, 'exp': 'Solids have definite shape and volume.'},
                {'q': 'Compressibility is maximum in:', 'opts': ['Gases', 'Liquids', 'Solids', 'Same in all'], 'correct': 0, 'exp': 'Gases can be compressed easily due to large spaces between particles.'},
                {'q': 'Liquids take the shape of:', 'opts': ['Container', 'Their own fixed shape', 'Cube', 'Sphere'], 'correct': 0, 'exp': 'Liquids take the shape of their container.'},
                {'q': 'The fourth state of matter is:', 'opts': ['Plasma', 'Gel', 'Crystal', 'Solution'], 'correct': 0, 'exp': 'Plasma is the fourth state of matter.'},
                {'q': 'Which has maximum density usually?', 'opts': ['Solid', 'Liquid', 'Gas', 'All same'], 'correct': 0, 'exp': 'Solids generally have highest density.'},
                {'q': 'Fluidity is a property of:', 'opts': ['Liquids and gases', 'Solids only', 'Gases only', 'Solids and liquids'], 'correct': 0, 'exp': 'Liquids and gases can flow.'},
                {'q': 'Rigidity is a property of:', 'opts': ['Solids', 'Liquids', 'Gases', 'All states'], 'correct': 0, 'exp': 'Solids are rigid and maintain their shape.'},
                {'q': 'Brownian motion is observed in:', 'opts': ['All states', 'Only gases', 'Only liquids', 'Only solids'], 'correct': 0, 'exp': 'Brownian motion can be observed in all states.'},
                {'q': 'Ice, water, and steam are:', 'opts': ['Same substance in different states', 'Different substances', 'Not related', 'Different compounds'], 'correct': 0, 'exp': 'They are all H2O in different states.'},
            ]
        elif chapter_title == 'Change of State of Matter':
            questions = [
                {'q': 'The process of changing from solid to liquid is:', 'opts': ['Melting', 'Freezing', 'Evaporation', 'Condensation'], 'correct': 0, 'exp': 'Melting is solid to liquid conversion.'},
                {'q': 'Freezing point of water is:', 'opts': ['0°C', '100°C', '-100°C', '50°C'], 'correct': 0, 'exp': 'Water freezes at 0°C at normal pressure.'},
                {'q': 'Boiling point of water is:', 'opts': ['100°C', '0°C', '50°C', '200°C'], 'correct': 0, 'exp': 'Water boils at 100°C at normal atmospheric pressure.'},
                {'q': 'The change from gas to liquid is called:', 'opts': ['Condensation', 'Evaporation', 'Sublimation', 'Melting'], 'correct': 0, 'exp': 'Condensation is gas to liquid.'},
                {'q': 'Sublimation is the change from:', 'opts': ['Solid to gas directly', 'Liquid to gas', 'Solid to liquid', 'Gas to solid'], 'correct': 0, 'exp': 'Sublimation skips the liquid state.'},
                {'q': 'Which substance sublimes?', 'opts': ['Camphor', 'Ice', 'Salt', 'Sugar'], 'correct': 0, 'exp': 'Camphor, dry ice, and naphthalene sublime.'},
                {'q': 'Latent heat is the heat:', 'opts': ['Required for change of state without temperature change', 'Required to increase temperature', 'Released during cooling', 'None'], 'correct': 0, 'exp': 'Latent heat changes state at constant temperature.'},
                {'q': 'During melting, temperature:', 'opts': ['Remains constant', 'Increases', 'Decreases', 'Fluctuates'], 'correct': 0, 'exp': 'Temperature stays constant during phase change.'},
                {'q': 'Latent heat of fusion of ice is:', 'opts': ['334 J/g', '2260 J/g', '100 J/g', '500 J/g'], 'correct': 0, 'exp': 'Latent heat of fusion of ice is 334 J/g.'},
                {'q': 'Dry ice is:', 'opts': ['Solid carbon dioxide', 'Solid water', 'Liquid nitrogen', 'Frozen oxygen'], 'correct': 0, 'exp': 'Dry ice is solid CO2.'},
            ]
        else:
            questions = generate_default_questions(module_name, chapter_title)
    
    elif module_name == 'Is Matter Around Us Pure?':
        if chapter_title == 'What is a Mixture?':
            questions = [
                {'q': 'A mixture is:', 'opts': ['Combination of two or more substances', 'A pure substance', 'An element', 'A compound'], 'correct': 0, 'exp': 'Mixture contains two or more substances.'},
                {'q': 'Components of a mixture:', 'opts': ['Retain their properties', 'Lose their properties', 'Form new compounds', 'Chemically combine'], 'correct': 0, 'exp': 'Components in a mixture keep their individual properties.'},
                {'q': 'Air is a:', 'opts': ['Mixture', 'Compound', 'Element', 'Pure substance'], 'correct': 0, 'exp': 'Air contains multiple gases mixed together.'},
                {'q': 'Which is NOT a mixture?', 'opts': ['Distilled water', 'Sea water', 'Air', 'Soil'], 'correct': 0, 'exp': 'Distilled water is pure H2O.'},
                {'q': 'In mixtures, components can be separated by:', 'opts': ['Physical methods', 'Chemical methods only', 'Cannot be separated', 'Nuclear reactions'], 'correct': 0, 'exp': 'Physical separation techniques work on mixtures.'},
                {'q': 'Brass is a mixture of:', 'opts': ['Copper and zinc', 'Iron and carbon', 'Gold and silver', 'Tin and lead'], 'correct': 0, 'exp': 'Brass is an alloy of copper and zinc.'},
                {'q': 'Sugar dissolved in water is a:', 'opts': ['Mixture', 'Compound', 'Element', 'New substance'], 'correct': 0, 'exp': 'Sugar solution is a mixture.'},
                {'q': 'Mixtures have:', 'opts': ['Variable composition', 'Fixed composition', 'No components', 'Only one component'], 'correct': 0, 'exp': 'Mixtures can have any proportion of components.'},
                {'q': 'Salt water is a:', 'opts': ['Homogeneous mixture', 'Heterogeneous mixture', 'Compound', 'Element'], 'correct': 0, 'exp': 'Salt water is uniform throughout (homogeneous).'},
                {'q': 'Sand and iron filings form a:', 'opts': ['Heterogeneous mixture', 'Homogeneous mixture', 'Compound', 'Solution'], 'correct': 0, 'exp': 'Components are visibly different (heterogeneous).'},
            ]
        elif chapter_title == 'Solutions':
            questions = [
                {'q': 'A solution is:', 'opts': ['Homogeneous mixture', 'Heterogeneous mixture', 'Compound', 'Suspension'], 'correct': 0, 'exp': 'Solutions are homogeneous mixtures.'},
                {'q': 'In a solution, the substance dissolved is called:', 'opts': ['Solute', 'Solvent', 'Solution', 'Residue'], 'correct': 0, 'exp': 'Solute is the dissolved substance.'},
                {'q': 'The substance in which solute dissolves is:', 'opts': ['Solvent', 'Solute', 'Solution', 'Mixture'], 'correct': 0, 'exp': 'Solvent dissolves the solute.'},
                {'q': 'A saturated solution:', 'opts': ['Cannot dissolve more solute at that temperature', 'Has no solute', 'Is very dilute', 'Is always warm'], 'correct': 0, 'exp': 'Saturated solution has maximum solute at given temperature.'},
                {'q': 'Concentration of solution is defined as:', 'opts': ['Amount of solute in given amount of solvent', 'Amount of solvent only', 'Volume of solution', 'Mass of container'], 'correct': 0, 'exp': 'Concentration = amount of solute per amount of solution/solvent.'},
                {'q': 'Solubility generally increases with:', 'opts': ['Temperature (for solids)', 'Pressure (for solids)', 'Decreasing temperature', 'Adding more solvent'], 'correct': 0, 'exp': 'Most solid solutes dissolve more at higher temperatures.'},
                {'q': 'Tincture of iodine is iodine dissolved in:', 'opts': ['Alcohol', 'Water', 'Oil', 'Acid'], 'correct': 0, 'exp': 'Tincture of iodine uses alcohol as solvent.'},
                {'q': 'Aerated drinks contain gas dissolved under:', 'opts': ['High pressure', 'Low pressure', 'Normal pressure', 'No pressure'], 'correct': 0, 'exp': 'CO2 is dissolved under high pressure.'},
                {'q': 'Mass by mass percentage of solute is:', 'opts': ['(Mass of solute / Mass of solution) × 100', '(Mass of solvent / Mass of solute) × 100', 'Mass of solute only', 'Volume percentage'], 'correct': 0, 'exp': 'Mass % = (mass solute / mass solution) × 100'},
                {'q': 'Alloys are:', 'opts': ['Solid solutions', 'Liquid solutions', 'Gaseous solutions', 'Not solutions'], 'correct': 0, 'exp': 'Alloys are homogeneous solid mixtures (solid solutions).'},
            ]
        else:
            questions = generate_default_questions(module_name, chapter_title)
    
    elif module_name == 'Atoms and Molecules':
        if chapter_title == 'What is an Atom?':
            questions = [
                {'q': 'Who proposed the atomic theory?', 'opts': ['John Dalton', 'J.J. Thomson', 'Rutherford', 'Bohr'], 'correct': 0, 'exp': 'Dalton proposed the first atomic theory in 1808.'},
                {'q': 'Atoms are:', 'opts': ['Building blocks of matter', 'Made of cells', 'Same as molecules', 'Visible to naked eye'], 'correct': 0, 'exp': 'Atoms are the fundamental units of matter.'},
                {'q': 'The radius of an atom is of the order of:', 'opts': ['10⁻¹⁰ m', '10⁻⁵ m', '10⁻² m', '10⁻¹⁵ m'], 'correct': 0, 'exp': 'Atomic radius is about 10⁻¹⁰ meters.'},
                {'q': 'Atoms of same element have:', 'opts': ['Same atomic number', 'Different atomic numbers', 'No protons', 'No electrons'], 'correct': 0, 'exp': 'Atomic number defines an element.'},
                {'q': 'The symbol for sodium is:', 'opts': ['Na', 'So', 'Sd', 'S'], 'correct': 0, 'exp': 'Na comes from Latin "Natrium".'},
                {'q': 'Atomic mass is expressed in:', 'opts': ['Atomic mass units (u)', 'Kilograms', 'Grams', 'Metres'], 'correct': 0, 'exp': 'Atomic mass unit (u) is used for atoms.'},
                {'q': '1 atomic mass unit equals:', 'opts': ['1/12 mass of C-12', '1/6 mass of C-12', 'Mass of hydrogen', 'Mass of oxygen'], 'correct': 0, 'exp': '1 u = 1/12 the mass of carbon-12 atom.'},
                {'q': 'The element with atomic number 1 is:', 'opts': ['Hydrogen', 'Helium', 'Oxygen', 'Carbon'], 'correct': 0, 'exp': 'Hydrogen has one proton, so atomic number is 1.'},
                {'q': 'Atoms are:', 'opts': ['Electrically neutral', 'Positively charged', 'Negatively charged', 'Magnetic'], 'correct': 0, 'exp': 'Atoms have equal protons and electrons.'},
                {'q': 'Atomicity of oxygen molecule is:', 'opts': ['2', '1', '3', '4'], 'correct': 0, 'exp': 'O₂ has 2 oxygen atoms, so atomicity is 2.'},
            ]
        else:
            questions = generate_default_questions(module_name, chapter_title)
    
    elif module_name == 'Motion':
        if chapter_title == 'Describing Motion':
            questions = [
                {'q': 'Distance is:', 'opts': ['Total path length covered', 'Shortest path between two points', 'A vector quantity', 'Negative sometimes'], 'correct': 0, 'exp': 'Distance is the total length of path traveled.'},
                {'q': 'Displacement is:', 'opts': ['Shortest distance from initial to final position', 'Total path length', 'Always positive', 'A scalar'], 'correct': 0, 'exp': 'Displacement is the shortest straight-line distance with direction.'},
                {'q': 'Which is a vector quantity?', 'opts': ['Displacement', 'Distance', 'Speed', 'Time'], 'correct': 0, 'exp': 'Displacement has both magnitude and direction.'},
                {'q': 'An object at rest has:', 'opts': ['Zero velocity', 'Constant velocity', 'Varying velocity', 'Maximum velocity'], 'correct': 0, 'exp': 'Rest means no motion, so velocity is zero.'},
                {'q': 'SI unit of displacement is:', 'opts': ['Metre', 'Kilometre', 'Centimetre', 'Mile'], 'correct': 0, 'exp': 'SI unit of length is metre.'},
                {'q': 'If a person walks 10m east and then 10m west, displacement is:', 'opts': ['0 m', '20 m', '10 m', '-10 m'], 'correct': 0, 'exp': 'Returns to starting point, so displacement is zero.'},
                {'q': 'Motion is:', 'opts': ['Change in position with time', 'Fixed position', 'Same as rest', 'Only vertical movement'], 'correct': 0, 'exp': 'Motion involves change of position over time.'},
                {'q': 'Uniform motion means:', 'opts': ['Equal distance in equal time intervals', 'Variable speed', 'Changing direction', 'Accelerated motion'], 'correct': 0, 'exp': 'Uniform motion has constant speed.'},
                {'q': 'Reference point is needed to describe:', 'opts': ['Motion', 'Mass', 'Weight', 'Density'], 'correct': 0, 'exp': 'Motion is relative and needs a reference point.'},
                {'q': 'Displacement can be:', 'opts': ['Zero, positive or negative', 'Only positive', 'Only negative', 'Only zero'], 'correct': 0, 'exp': 'Displacement depends on direction and can be any of these.'},
            ]
        elif chapter_title == 'Equations of Motion':
            questions = [
                {'q': 'First equation of motion is:', 'opts': ['v = u + at', 's = ut + ½at²', 'v² = u² + 2as', 'F = ma'], 'correct': 0, 'exp': 'First equation relates velocity, initial velocity, acceleration and time.'},
                {'q': 'Second equation of motion is:', 'opts': ['s = ut + ½at²', 'v = u + at', 'v² = u² + 2as', 's = vt'], 'correct': 0, 'exp': 'Second equation gives displacement.'},
                {'q': 'Third equation of motion is:', 'opts': ['v² = u² + 2as', 'v = u + at', 's = ut + ½at²', 'a = v/t'], 'correct': 0, 'exp': 'Third equation relates velocities with displacement.'},
                {'q': 'In equations of motion, u stands for:', 'opts': ['Initial velocity', 'Final velocity', 'Uniform velocity', 'Ultimate velocity'], 'correct': 0, 'exp': 'u is the initial velocity.'},
                {'q': 'If initial velocity is 0, the body starts from:', 'opts': ['Rest', 'Motion', 'High speed', 'Terminal velocity'], 'correct': 0, 'exp': 'u = 0 means starting from rest.'},
                {'q': 'For retardation, acceleration is:', 'opts': ['Negative', 'Positive', 'Zero', 'Infinite'], 'correct': 0, 'exp': 'Retardation is negative acceleration.'},
                {'q': 'A car accelerates from 20 m/s to 60 m/s in 4s. Acceleration is:', 'opts': ['10 m/s²', '20 m/s²', '15 m/s²', '40 m/s²'], 'correct': 0, 'exp': 'a = (60-20)/4 = 10 m/s²'},
                {'q': 'Object dropped from height has initial velocity:', 'opts': ['0 m/s', '9.8 m/s', '10 m/s', 'Varies'], 'correct': 0, 'exp': 'Dropped means released from rest, u = 0.'},
                {'q': 'If v = u, then acceleration is:', 'opts': ['Zero', 'Positive', 'Negative', 'Cannot determine'], 'correct': 0, 'exp': 'Same initial and final velocity means a = 0.'},
                {'q': 'Distance covered in nth second formula is:', 'opts': ['sₙ = u + a(n - ½)', 's = ut + ½at²', 'v = u + at', 's = (u+v)t/2'], 'correct': 0, 'exp': 'Distance in nth second uses this special formula.'},
            ]
        else:
            questions = generate_default_questions(module_name, chapter_title)
    
    if not questions:
        questions = generate_default_questions(module_name, chapter_title)
    
    return questions


def get_hots_questions(module_name, chapter_title):
    """Generate 3 HOTS questions for a chapter."""
    hots = []
    
    if module_name == 'Matter in Our Surroundings':
        if chapter_title == 'Physical Nature of Matter':
            hots = [
                {'q': 'A perfume bottle is opened at one corner of a room. After some time, the fragrance is smelled throughout the room. Explain this phenomenon and state two factors that would make the fragrance spread faster.', 'opts': ['Diffusion; higher temperature and smaller room size', 'Evaporation; lower pressure and bigger room', 'Condensation; more perfume and cold room', 'Osmosis; humid air and larger molecules'], 'correct': 0, 'exp': 'Diffusion causes particles to spread. Higher temperature increases kinetic energy, making particles move faster.'},
                {'q': 'Why does a drop of ink spread in water on its own without stirring, but a sugar cube needs to be stirred to dissolve faster?', 'opts': ['Ink particles are much smaller and diffuse easily; sugar is solid with slower dissolution', 'Ink is lighter than sugar', 'Sugar does not dissolve', 'Water repels sugar'], 'correct': 0, 'exp': 'Ink particles are already dispersed and diffuse quickly. Sugar is solid and needs mechanical energy to break bonds.'},
                {'q': 'Two gases are kept in separate containers at the same temperature. If container A has larger molecules than container B, in which container will diffusion be faster when both are opened?', 'opts': ['Container B (smaller molecules)', 'Container A (larger molecules)', 'Same in both', 'Neither will diffuse'], 'correct': 0, 'exp': 'Smaller molecules move faster at same temperature, so they diffuse faster.'},
            ]
        elif chapter_title == 'Change of State of Matter':
            hots = [
                {'q': 'Ice at 0°C is more effective as a coolant than water at 0°C. Explain why.', 'opts': ['Ice absorbs latent heat of fusion while melting', 'Ice is colder than water', 'Water cannot cool things', 'Ice has more mass'], 'correct': 0, 'exp': 'Ice at 0°C absorbs 334 J/g (latent heat) while melting, providing additional cooling.'},
                {'q': 'Why do we feel cool when we come out of a swimming pool on a hot day?', 'opts': ['Water evaporates taking heat from our body', 'Pool water is always cold', 'Air is cool near pools', 'Our body temperature drops in water'], 'correct': 0, 'exp': 'Evaporation of water from skin absorbs latent heat from the body, causing cooling.'},
                {'q': 'Why does the temperature remain constant during the boiling of water even though heat is continuously supplied?', 'opts': ['Heat is used to break intermolecular bonds (latent heat)', 'Thermometer is faulty', 'Water absorbs no heat', 'Heat escapes to surroundings'], 'correct': 0, 'exp': 'During phase change, heat is used as latent heat to change state, not to increase temperature.'},
            ]
        else:
            hots = generate_default_hots(module_name, chapter_title)
    
    elif module_name == 'Motion':
        if chapter_title == 'Equations of Motion':
            hots = [
                {'q': 'A ball is thrown vertically upward with velocity 20 m/s. Find the maximum height reached and total time of flight. (g = 10 m/s²)', 'opts': ['Height = 20m, Time = 4s', 'Height = 40m, Time = 4s', 'Height = 20m, Time = 2s', 'Height = 10m, Time = 2s'], 'correct': 0, 'exp': 'At max height, v = 0. Using v² = u² - 2gh: 0 = 400 - 20h, h = 20m. Time to reach max = u/g = 2s. Total = 4s.'},
                {'q': 'Two cars start from rest with accelerations 2 m/s² and 4 m/s². After how long will the second car be 80m ahead of the first?', 'opts': ['√80 ≈ 8.94 s', '10 s', '5 s', '4 s'], 'correct': 0, 'exp': 'Distance difference = ½(4)t² - ½(2)t² = 80. So t² = 80, t ≈ 8.94s'},
                {'q': 'A train travels half the distance at 40 km/h and the remaining half at 60 km/h. Find the average speed for the whole journey.', 'opts': ['48 km/h', '50 km/h', '55 km/h', '45 km/h'], 'correct': 0, 'exp': 'Average speed = 2×40×60/(40+60) = 4800/100 = 48 km/h'},
            ]
        else:
            hots = generate_default_hots(module_name, chapter_title)
    
    if not hots:
        hots = generate_default_hots(module_name, chapter_title)
    
    return hots


def generate_default_questions(module_name, chapter_title):
    """Generate generic questions."""
    questions = []
    for i in range(10):
        questions.append({
            'q': f'{chapter_title} - Question {i+1}: A concept question related to {module_name}.',
            'opts': [f'Correct Answer', f'Wrong Option A', f'Wrong Option B', f'Wrong Option C'],
            'correct': 0,
            'exp': f'Explanation for question {i+1} about {chapter_title}.'
        })
    return questions


def generate_default_hots(module_name, chapter_title):
    """Generate generic HOTS questions."""
    hots = []
    for i in range(3):
        hots.append({
            'q': f'{chapter_title} - HOTS {i+1}: An application-based problem on {module_name}.',
            'opts': [f'Correct Answer', f'Wrong A', f'Wrong B', f'Wrong C'],
            'correct': 0,
            'exp': f'Detailed explanation for HOTS {i+1}.'
        })
    return hots


class Command(BaseCommand):
    help = 'Populate Science subject with modules, chapters, questions, and HOTS'

    def add_arguments(self, parser):
        parser.add_argument(
            '--clear-existing',
            action='store_true',
            help='Delete existing data before creating new ones',
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
            ChapterHOTS.objects.filter(chapter__module__subject=subject).delete()
            ModuleContent.objects.filter(chapter__module__subject=subject).delete()
            ModuleChapter.objects.filter(module__subject=subject).delete()
            Module.objects.filter(subject=subject).delete()
            self.stdout.write(self.style.SUCCESS('Existing data deleted.'))

        accounts = list(Account.objects.filter(is_superuser=False)[:1])
        if not accounts:
            accounts = list(Account.objects.filter(is_superuser=True)[:1])
        created_by = accounts[0] if accounts else None

        stats = {'modules': 0, 'chapters': 0, 'questions': 0, 'options': 0, 'module_contents': 0, 'hots': 0}

        with transaction.atomic():
            for module_order, (module_name, module_data) in enumerate(SCIENCE_MODULES.items(), start=1):
                self.stdout.write(f'\nCreating module: {module_name}')
                
                module, created = Module.objects.get_or_create(
                    name=module_name, subject=subject,
                    defaults={'description': module_data['description'], 'order': module_order, 
                              'is_active': True, 'is_enabled': True, 'created_by': created_by}
                )
                if created:
                    stats['modules'] += 1

                for chapter_order, chapter_data in enumerate(module_data['chapters'], start=1):
                    chapter, created = ModuleChapter.objects.get_or_create(
                        module=module, order=chapter_order,
                        defaults={'title': chapter_data['title'], 'description': chapter_data['description'],
                                  'is_enabled': True, 'is_important': chapter_order <= 2, 'has_hots': True, 'created_by': created_by}
                    )
                    if created:
                        stats['chapters'] += 1
                    else:
                        continue

                    chapter_questions = get_chapter_questions(module_name, chapter_data['title'])
                    for q_order, q_data in enumerate(chapter_questions[:10], start=1):
                        question = Question.objects.create(
                            question_text=q_data['q'], question_type='mcq_single',
                            exp_points=random.randint(10, 30), difficulty_level=random.choice(['easy', 'medium', 'hard']),
                            explanation=q_data['exp'], is_active=True, is_hots=False, created_by=created_by
                        )
                        stats['questions'] += 1
                        for opt_order, opt_text in enumerate(q_data['opts'], start=1):
                            Option.objects.get_or_create(question=question, option_text=opt_text,
                                                  defaults={'is_correct': (opt_order - 1 == q_data['correct']), 'order': opt_order})
                            stats['options'] += 1
                        ModuleContent.objects.get_or_create(chapter=chapter, order=q_order,
                                                     defaults={'content_type': 'question', 'question': question, 'created_by': created_by})
                        stats['module_contents'] += 1

                    hots_questions = get_hots_questions(module_name, chapter_data['title'])
                    for hots_order, hots_data in enumerate(hots_questions[:3], start=1):
                        hots_q = Question.objects.create(
                            question_text=hots_data['q'], question_type='mcq_single',
                            exp_points=random.randint(40, 60), difficulty_level='hard',
                            explanation=hots_data['exp'], is_active=True, is_hots=True, created_by=created_by
                        )
                        stats['questions'] += 1
                        for opt_order, opt_text in enumerate(hots_data['opts'], start=1):
                            Option.objects.get_or_create(question=hots_q, option_text=opt_text,
                                                  defaults={'is_correct': (opt_order - 1 == hots_data['correct']), 'order': opt_order})
                            stats['options'] += 1
                        ChapterHOTS.objects.get_or_create(chapter=chapter, question=hots_q, 
                                                          defaults={'order': hots_order, 'created_by': created_by})
                        stats['hots'] += 1

                    self.stdout.write(f'  ✓ {chapter_data["title"]}: 10 questions + 3 HOTS')

        self.stdout.write('\n' + '=' * 70)
        self.stdout.write(self.style.SUCCESS(f'SUCCESS! {SUBJECT_NAME} populated:'))
        self.stdout.write(f'  Modules: {stats["modules"]}, Chapters: {stats["chapters"]}, Questions: {stats["questions"]}, HOTS: {stats["hots"]}')

