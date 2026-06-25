"""
Django management command to create complete subject structure:
- 6 subjects: Science, Maths, English, History, Computer Science, Hindi
- 10 modules per subject
- 6 chapters per module
- 6 questions per chapter (as module content)
"""

from django.core.management.base import BaseCommand
from gyaan_buddy.subjects.models import Subject, Module, ModuleChapter, ModuleContent, Question, Option
from gyaan_buddy.users.models import Account
from faker import Faker
import random
import os
from django.conf import settings
from django.core.files import File

fake = Faker()

SUBJECTS = [
    {'name': 'Science', 'code': 'SCI', 'logo_file': 'science.png'},
    {'name': 'Maths', 'code': 'MATH', 'logo_file': 'maths.png'},
    {'name': 'English', 'code': 'ENG', 'logo_file': 'english.png'},
    {'name': 'History', 'code': 'HIST', 'logo_file': 'history.png'},
    {'name': 'Computer Science', 'code': 'CS', 'logo_file': 'science.png'},
    {'name': 'Hindi', 'code': 'HIN', 'logo_file': 'english.png'},
]

MODULE_NAMES = [
    'Introduction to {subject}',
    'Fundamentals of {subject}',
    'Advanced {subject} Concepts',
    '{subject} Applications',
    '{subject} Theory and Practice',
    'Exploring {subject}',
    'Mastering {subject}',
    '{subject} Problem Solving',
    '{subject} Analysis and Design',
    'Advanced Topics in {subject}',
]

CHAPTER_TITLES = [
    'Chapter 1: Basics',
    'Chapter 2: Core Concepts',
    'Chapter 3: Intermediate Topics',
    'Chapter 4: Advanced Applications',
    'Chapter 5: Problem Solving',
    'Chapter 6: Review and Practice',
]

QUESTION_TEMPLATES = {
    'Science': [
        "What is the main principle behind {topic}?",
        "Explain how {topic} works in nature.",
        "What are the key components of {topic}?",
        "Describe the process of {topic}.",
        "Why is {topic} important in science?",
        "What are the applications of {topic}?",
    ],
    'Maths': [
        "Solve the following problem: {topic}",
        "What is the formula for {topic}?",
        "Explain the concept of {topic}.",
        "Calculate the value of {topic}.",
        "What are the properties of {topic}?",
        "How do you apply {topic} in real life?",
    ],
    'English': [
        "What is the meaning of {topic}?",
        "Explain the grammar rule for {topic}.",
        "How do you use {topic} in a sentence?",
        "What is the difference between {topic} and {topic2}?",
        "Analyze the literary device in {topic}.",
        "Write a paragraph about {topic}.",
    ],
    'History': [
        "When did {topic} occur?",
        "What were the causes of {topic}?",
        "Who were the key figures in {topic}?",
        "What was the impact of {topic}?",
        "Explain the significance of {topic}.",
        "How did {topic} change history?",
    ],
    'Computer Science': [
        "What is {topic} in programming?",
        "Explain the algorithm for {topic}.",
        "How does {topic} work in computer systems?",
        "What are the advantages of {topic}?",
        "Describe the data structure for {topic}.",
        "How do you implement {topic}?",
    ],
    'Hindi': [
        "{topic} का अर्थ क्या है?",
        "{topic} का उपयोग कैसे करें?",
        "{topic} के बारे में एक वाक्य लिखें।",
        "{topic} और {topic2} में क्या अंतर है?",
        "{topic} की व्याकरणिक व्याख्या करें।",
        "{topic} पर एक पैराग्राफ लिखें।",
    ],
}

OPTION_TEMPLATES = {
    'Science': [
        "It involves chemical reactions",
        "It follows physical laws",
        "It requires energy transfer",
        "It depends on temperature",
        "It involves molecular interactions",
        "It follows biological processes",
        "It requires specific conditions",
        "It involves natural phenomena",
    ],
    'Maths': [
        "The answer is {num}",
        "It equals {num}",
        "The result is {num}",
        "It can be calculated as {num}",
        "The formula gives {num}",
        "It simplifies to {num}",
        "The value is {num}",
        "It evaluates to {num}",
    ],
    'English': [
        "It means {word}",
        "It refers to {word}",
        "It is used for {word}",
        "It describes {word}",
        "It indicates {word}",
        "It represents {word}",
        "It signifies {word}",
        "It denotes {word}",
    ],
    'History': [
        "It happened in {year}",
        "It was caused by {event}",
        "It involved {person}",
        "It led to {outcome}",
        "It occurred during {period}",
        "It was part of {movement}",
        "It resulted in {change}",
        "It influenced {development}",
    ],
    'Computer Science': [
        "It uses {concept}",
        "It implements {structure}",
        "It follows {pattern}",
        "It requires {resource}",
        "It processes {data}",
        "It uses {algorithm}",
        "It stores {information}",
        "It executes {operation}",
    ],
    'Hindi': [
        "{word} का मतलब है",
        "{word} से संबंधित",
        "{word} के लिए उपयोग",
        "{word} की विशेषता",
        "{word} का उदाहरण",
        "{word} से जुड़ा हुआ",
        "{word} का प्रकार",
        "{word} की परिभाषा",
    ],
}


class Command(BaseCommand):
    help = 'Create complete subject structure: 6 subjects, 10 modules each, 6 chapters each, 6 questions per chapter'

    def add_arguments(self, parser):
        parser.add_argument(
            '--clear-existing',
            action='store_true',
            help='Delete all existing subjects, modules, chapters, and questions before creating new ones',
        )

    def handle(self, *args, **options):
        clear_existing = options.get('clear_existing', False)
        
        if clear_existing:
            self.stdout.write('Deleting all existing data...')
            ModuleContent.objects.all().delete()
            ModuleChapter.objects.all().delete()
            Module.objects.all().delete()
            Question.objects.all().delete()
            Subject.objects.all().delete()
            self.stdout.write(self.style.SUCCESS('All existing data deleted.'))

        accounts = list(Account.objects.filter(is_superuser=False))
        if not accounts:
            accounts = list(Account.objects.filter(is_superuser=True))
        created_by = accounts[0] if accounts else None

        if not created_by:
            self.stdout.write(self.style.WARNING('No user found. Some fields may be None.'))

        logo_dir = os.path.join(settings.MEDIA_ROOT, 'subject_logos')
        
        self.stdout.write('Creating 6 subjects...')
        subjects_dict = {}
        
        for subject_data in SUBJECTS:
            subject_name = subject_data['name']
            subject_code = subject_data['code']
            logo_file = subject_data['logo_file']
            
            subject, created = Subject.objects.get_or_create(
                name=subject_name,
                defaults={
                    'code': subject_code,
                    'description': f'Comprehensive course on {subject_name}',
                    'is_active': True,
                    'created_by': created_by,
                }
            )
            
            if not subject.logo or subject.logo.name == '':
                logo_path = os.path.join(logo_dir, logo_file)
                if os.path.exists(logo_path):
                    with open(logo_path, 'rb') as f:
                        subject.logo.save(logo_file, File(f), save=False)
                        subject.save()
                else:
                    logo_files = [f for f in os.listdir(logo_dir) if f.endswith(('.png', '.jpg', '.jpeg'))]
                    if logo_files:
                        fallback_logo = os.path.join(logo_dir, logo_files[0])
                        with open(fallback_logo, 'rb') as f:
                            subject.logo.save(logo_files[0], File(f), save=False)
                            subject.save()
            
            subjects_dict[subject_name] = subject
            if created:
                self.stdout.write(f'  Created subject: {subject_name}')
            else:
                self.stdout.write(f'  Subject already exists: {subject_name}')

        total_questions = 0
        total_modules = 0
        total_chapters = 0
        total_contents = 0
        total_options = 0
        total_mcq_questions = 0

        for subject_name, subject in subjects_dict.items():
            self.stdout.write(f'\nProcessing subject: {subject_name}')
            
            modules = []
            for module_num in range(1, 11):
                module_name = MODULE_NAMES[module_num - 1].format(subject=subject_name)
                
                module, created = Module.objects.get_or_create(
                    name=module_name,
                    subject=subject,
                    defaults={
                        'description': f'Module {module_num} covering important topics in {subject_name}',
                        'order': module_num,
                        'is_active': True,
                        'is_enabled': True,
                        'created_by': created_by,
                    }
                )
                
                if created:
                    modules.append(module)
                    total_modules += 1
                else:
                    modules.append(module)
            
            self.stdout.write(f'  Created/Found {len(modules)} modules')

            for module in modules:
                chapters = []
                for chapter_num in range(1, 7):
                    chapter_title = CHAPTER_TITLES[chapter_num - 1]
                    
                    chapter, created = ModuleChapter.objects.get_or_create(
                        module=module,
                        order=chapter_num,
                        defaults={
                            'title': chapter_title,
                            'description': f'{chapter_title} in {module.name}',
                            'is_enabled': True,
                            'is_important': chapter_num <= 2,
                            'created_by': created_by,
                        }
                    )
                    
                    if created:
                        chapters.append(chapter)
                        total_chapters += 1
                    else:
                        chapters.append(chapter)

                for chapter in chapters:
                    existing_content_count = chapter.contents.count()
                    if existing_content_count >= 6:
                        self.stdout.write(f'    Chapter "{chapter.title}" already has {existing_content_count} contents, skipping...')
                        continue
                    
                    questions_needed = 6 - existing_content_count
                    questions = []
                    for question_num in range(1, questions_needed + 1):
                        templates = QUESTION_TEMPLATES.get(subject_name, QUESTION_TEMPLATES['Science'])
                        topic = fake.word().title()
                        topic2 = fake.word().title()
                        question_text = random.choice(templates).format(topic=topic, topic2=topic2)
                        
                        question = Question(
                            question_text=question_text,
                            question_type=random.choice(['mcq_single', 'mcq_multiple', 'short_answer']),
                            exp_points=random.randint(10, 50),
                            difficulty_level=random.choice(['easy', 'medium', 'hard']),
                            explanation=fake.text(max_nb_chars=200),
                            is_active=True,
                            created_by=created_by,
                        )
                        questions.append(question)
                        total_questions += 1
                    
                    created_questions = Question.objects.bulk_create(questions)
                    
                    options_to_create = []
                    option_templates = OPTION_TEMPLATES.get(subject_name, OPTION_TEMPLATES['Science'])
                    mcq_count_in_batch = 0
                    
                    for question in created_questions:
                        if question.question_type in ['mcq_single', 'mcq_multiple']:
                            total_mcq_questions += 1
                            mcq_count_in_batch += 1
                            num_options = random.randint(4, 5)
                            num_correct = 1 if question.question_type == 'mcq_single' else random.randint(1, 2)
                            correct_indices = random.sample(range(num_options), num_correct)
                            
                            used_option_texts = set()
                            for j in range(num_options):
                                if subject_name == 'Maths':
                                    option_text = f"{random.randint(1, 100)}"
                                elif subject_name == 'History':
                                    option_text = random.choice([
                                        f"In {random.randint(1800, 2020)}",
                                        f"During {fake.word().title()} period",
                                        f"Led by {fake.name()}",
                                        f"Resulted in {fake.word().title()}",
                                        f"Caused by {fake.word().title()}",
                                    ])
                                elif subject_name == 'Hindi':
                                    option_text = f"{fake.word()} {fake.word()}"
                                else:
                                    template = random.choice(option_templates)
                                    if '{' in template:
                                        try:
                                            option_text = template.format(
                                                num=random.randint(1, 100),
                                                word=fake.word(),
                                                year=random.randint(1800, 2020),
                                                event=fake.word().title(),
                                                person=fake.name(),
                                                outcome=fake.word().title(),
                                                period=fake.word().title(),
                                                movement=fake.word().title(),
                                                change=fake.word().title(),
                                                development=fake.word().title(),
                                                concept=fake.word().title(),
                                                structure=fake.word().title(),
                                                pattern=fake.word().title(),
                                                resource=fake.word().title(),
                                                data=fake.word().title(),
                                                algorithm=fake.word().title(),
                                                information=fake.word().title(),
                                                operation=fake.word().title(),
                                            )
                                        except KeyError:
                                            option_text = fake.sentence(nb_words=4)
                                    else:
                                        option_text = template
                                
                                counter = 1
                                original_text = option_text
                                while option_text in used_option_texts:
                                    option_text = f"{original_text} ({counter})"
                                    counter += 1
                                used_option_texts.add(option_text)
                                
                                option = Option(
                                    question=question,
                                    option_text=option_text[:500],
                                    is_correct=(j in correct_indices),
                                    order=j + 1
                                )
                                options_to_create.append(option)
                                total_options += 1
                    
                    if options_to_create:
                        Option.objects.bulk_create(options_to_create)
                        self.stdout.write(f'      Created {len(options_to_create)} options for {mcq_count_in_batch} MCQ questions')
                    
                    contents = []
                    start_order = existing_content_count + 1
                    for idx, question in enumerate(created_questions, start=0):
                        content = ModuleContent(
                            chapter=chapter,
                            content_type='question',
                            question=question,
                            order=start_order + idx,
                            created_by=created_by,
                        )
                        contents.append(content)
                        total_contents += 1
                    
                    ModuleContent.objects.bulk_create(contents)

        self.stdout.write('\n' + '=' * 70)
        self.stdout.write(self.style.SUCCESS('SUCCESS! Created complete subject structure:'))
        self.stdout.write('=' * 70)
        self.stdout.write(f'  Subjects: {len(subjects_dict)}')
        self.stdout.write(f'  Modules: {total_modules} (10 per subject)')
        self.stdout.write(f'  Chapters: {total_chapters} (6 per module)')
        self.stdout.write(f'  Questions: {total_questions} (6 per chapter)')
        self.stdout.write(f'  MCQ Questions: {total_mcq_questions} (with options)')
        self.stdout.write(f'  Options: {total_options} (for MCQ questions)')
        self.stdout.write(f'  Module Contents: {total_contents} (6 per chapter)')
        self.stdout.write('=' * 70)
        
        if total_mcq_questions > 0:
            all_mcq_questions = Question.objects.filter(
                question_type__in=['mcq_single', 'mcq_multiple']
            )
            questions_without_options = [
                q for q in all_mcq_questions 
                if q.options.count() == 0
            ]
            
            if questions_without_options:
                self.stdout.write(self.style.WARNING(
                    f'  WARNING: {len(questions_without_options)} MCQ questions found without options!'
                ))
            else:
                self.stdout.write(self.style.SUCCESS(
                    f'  ✓ All {total_mcq_questions} MCQ questions have options!'
                ))

