"""
Django management command to create dummy data for Question table.
Deletes all existing entries first, then creates 100 new entries.
"""

from django.core.management.base import BaseCommand
from gyaan_buddy.subjects.models import Question, Option
from gyaan_buddy.users.models import Account
from faker import Faker
import random

fake = Faker()

QUESTION_TEMPLATES = [
    "What is the main concept of {topic}?",
    "Explain the significance of {topic}.",
    "How does {topic} work?",
    "What are the key features of {topic}?",
    "Describe the process of {topic}.",
    "What is the relationship between {topic} and {topic2}?",
    "Why is {topic} important?",
    "What are the advantages of {topic}?",
    "Compare and contrast {topic} with {topic2}.",
    "What are the applications of {topic}?"
]


class Command(BaseCommand):
    help = 'Create 100 dummy questions. Deletes all existing questions first.'

    def handle(self, *args, **options):
        self.stdout.write('Deleting all existing questions...')
        Question.objects.all().delete()
        self.stdout.write(self.style.SUCCESS('All questions deleted.'))

        accounts = list(Account.objects.filter(is_superuser=False))
        created_by = random.choice(accounts) if accounts else None

        self.stdout.write('Creating 100 dummy questions...')
        
        questions = []
        for i in range(100):
            question_type = random.choice(['mcq_single', 'mcq_multiple', 'short_answer'])
            difficulty = random.choice(['easy', 'medium', 'hard'])
            
            topic = fake.word().title()
            topic2 = fake.word().title()
            question_text = random.choice(QUESTION_TEMPLATES).format(topic=topic, topic2=topic2)
            
            question = Question(
                question_text=question_text,
                question_type=question_type,
                exp_points=random.randint(5, 50),
                difficulty_level=difficulty,
                explanation=fake.text(max_nb_chars=200),
                is_active=random.choice([True, True, True, False]),
                created_by=created_by
            )
            questions.append(question)
        
        created_questions = Question.objects.bulk_create(questions)
        
        self.stdout.write('Creating options for MCQ questions...')
        options_to_create = []
        for question in created_questions:
            if question.question_type in ['mcq_single', 'mcq_multiple']:
                num_options = random.randint(3, 5)
                num_correct = 1 if question.question_type == 'mcq_single' else random.randint(1, 2)
                
                correct_indices = random.sample(range(num_options), num_correct)
                
                for j in range(num_options):
                    option = Option(
                        question=question,
                        option_text=fake.sentence(nb_words=5),
                        is_correct=(j in correct_indices),
                        order=j + 1
                    )
                    options_to_create.append(option)
        
        Option.objects.bulk_create(options_to_create)
        
        self.stdout.write(
            self.style.SUCCESS(f'Successfully created {len(created_questions)} questions with options!')
        )

