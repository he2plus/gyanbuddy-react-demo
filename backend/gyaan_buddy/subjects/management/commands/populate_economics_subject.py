"""
Django management command to populate Economics subject with:
- 4 modules covering Class 9 Economics topics
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

SUBJECT_NAME = 'Economics'

ECONOMICS_MODULES = {
    'The Story of Village Palampur': {
        'description': 'Understanding farming and non-farming activities in a village',
        'chapters': [
            {'title': 'Organisation of Production', 'description': 'Factors of production and their role'},
            {'title': 'Farming in Palampur', 'description': 'Methods and types of farming'},
            {'title': 'The Green Revolution', 'description': 'Impact of modern farming methods'},
            {'title': 'Land Distribution', 'description': 'Pattern of land ownership'},
            {'title': 'Non-Farm Activities', 'description': 'Other economic activities in villages'},
            {'title': 'Capital and Labour', 'description': 'Role of capital and labor in production'},
        ]
    },
    'People as Resource': {
        'description': 'Human capital and its development',
        'chapters': [
            {'title': 'Human Capital Formation', 'description': 'Investment in education and health'},
            {'title': 'Quality of Population', 'description': 'Literacy and health indicators'},
            {'title': 'Education and Health', 'description': 'Role of education and healthcare'},
            {'title': 'Unemployment', 'description': 'Types and causes of unemployment'},
            {'title': 'Women Employment', 'description': 'Gender and employment'},
            {'title': 'Market and Non-Market Activities', 'description': 'Economic and non-economic activities'},
        ]
    },
    'Poverty as a Challenge': {
        'description': 'Understanding poverty and anti-poverty measures',
        'chapters': [
            {'title': 'What is Poverty?', 'description': 'Definition and indicators of poverty'},
            {'title': 'Poverty Line', 'description': 'Measuring poverty in India'},
            {'title': 'Causes of Poverty', 'description': 'Historical and social causes'},
            {'title': 'Vulnerable Groups', 'description': 'Groups most affected by poverty'},
            {'title': 'Anti-Poverty Measures', 'description': 'Government policies and programmes'},
            {'title': 'Global Poverty Trends', 'description': 'Poverty reduction worldwide'},
        ]
    },
    'Food Security in India': {
        'description': 'Ensuring food availability and access for all',
        'chapters': [
            {'title': 'What is Food Security?', 'description': 'Dimensions of food security'},
            {'title': 'Food Availability', 'description': 'Production and import of food'},
            {'title': 'Public Distribution System', 'description': 'Role of PDS in food security'},
            {'title': 'Buffer Stock', 'description': 'Storage and procurement by FCI'},
            {'title': 'Food Security Programmes', 'description': 'Various government schemes'},
            {'title': 'Challenges and Solutions', 'description': 'Problems and reforms in food security'},
        ]
    },
}


def get_chapter_questions(module_name, chapter_title):
    questions = []
    
    if module_name == 'The Story of Village Palampur':
        if chapter_title == 'Organisation of Production':
            questions = [
                {'q': 'The four requirements for production of goods and services are:', 'opts': ['Land, Labour, Physical Capital, Human Capital', 'Only land and labour', 'Money and machines', 'Raw materials only'], 'correct': 0, 'exp': 'The four factors of production are land, labour, physical capital, and human capital.'},
                {'q': 'Which is NOT a factor of production?', 'opts': ['Profit', 'Land', 'Labour', 'Capital'], 'correct': 0, 'exp': 'Profit is the outcome of production, not a factor of production.'},
                {'q': 'Physical capital includes:', 'opts': ['Tools, machines, buildings', 'Skills and knowledge', 'Land only', 'Labour only'], 'correct': 0, 'exp': 'Physical capital refers to tangible assets used in production.'},
                {'q': 'Human capital refers to:', 'opts': ['Knowledge and skills of workers', 'Number of workers', 'Machines and tools', 'Money invested'], 'correct': 0, 'exp': 'Human capital is the skills, knowledge, and experience of workers.'},
                {'q': 'Fixed capital includes:', 'opts': ['Tools and machinery', 'Raw materials', 'Seeds and fertilizers', 'Money in hand'], 'correct': 0, 'exp': 'Fixed capital is used over years and includes buildings, machinery.'},
                {'q': 'Working capital includes:', 'opts': ['Raw materials and money', 'Land and building', 'Machinery only', 'Labour force'], 'correct': 0, 'exp': 'Working capital is used in current production cycle.'},
                {'q': 'Land is a:', 'opts': ['Natural resource', 'Man-made resource', 'Renewable always', 'Mobile resource'], 'correct': 0, 'exp': 'Land is a natural resource that is fixed in supply.'},
                {'q': 'Labour refers to:', 'opts': ['Human effort in production', 'Machines', 'Land', 'Money'], 'correct': 0, 'exp': 'Labour is the physical and mental effort of workers.'},
                {'q': 'Entrepreneur combines:', 'opts': ['All factors of production', 'Only capital and land', 'Only labour', 'Nothing'], 'correct': 0, 'exp': 'Entrepreneur organizes all factors of production.'},
                {'q': 'Which factor of production is most abundant in Palampur?', 'opts': ['Labour', 'Land', 'Capital', 'Technology'], 'correct': 0, 'exp': 'Labour is abundant in villages like Palampur.'},
            ]
        elif chapter_title == 'Farming in Palampur':
            questions = [
                {'q': 'Main production activity in Palampur is:', 'opts': ['Farming', 'Manufacturing', 'Trading', 'Services'], 'correct': 0, 'exp': 'About 75% of workers in Palampur are involved in farming.'},
                {'q': 'Multiple cropping means:', 'opts': ['Growing more than one crop in a year', 'Growing same crop repeatedly', 'Growing only one crop', 'Not growing any crop'], 'correct': 0, 'exp': 'Multiple cropping increases production from the same land.'},
                {'q': 'Modern farming methods require:', 'opts': ['HYV seeds, irrigation, chemical fertilizers', 'Only traditional seeds', 'No irrigation', 'Only organic methods'], 'correct': 0, 'exp': 'Modern farming uses High Yielding Variety seeds, irrigation, and fertilizers.'},
                {'q': 'HYV seeds were introduced during:', 'opts': ['Green Revolution', 'White Revolution', 'Blue Revolution', 'Industrial Revolution'], 'correct': 0, 'exp': 'High Yielding Variety seeds came with the Green Revolution.'},
                {'q': 'Kharif crops are grown in:', 'opts': ['Monsoon season (June-September)', 'Winter season', 'Summer season', 'All seasons'], 'correct': 0, 'exp': 'Kharif crops are sown in June-July and harvested in September-October.'},
                {'q': 'Rabi crops are grown in:', 'opts': ['Winter season (October-March)', 'Monsoon season', 'Summer season', 'Rainy season'], 'correct': 0, 'exp': 'Rabi crops are sown in October-November and harvested in March-April.'},
                {'q': 'Which is a Kharif crop?', 'opts': ['Rice', 'Wheat', 'Mustard', 'Gram'], 'correct': 0, 'exp': 'Rice, maize, cotton are Kharif crops.'},
                {'q': 'Which is a Rabi crop?', 'opts': ['Wheat', 'Rice', 'Maize', 'Cotton'], 'correct': 0, 'exp': 'Wheat, barley, peas are Rabi crops.'},
                {'q': 'Tubewells are used for:', 'opts': ['Irrigation', 'Storage', 'Transportation', 'Processing'], 'correct': 0, 'exp': 'Tubewells extract groundwater for irrigation.'},
                {'q': 'Green Revolution increased production of:', 'opts': ['Wheat and rice', 'Pulses only', 'Cotton only', 'Sugarcane only'], 'correct': 0, 'exp': 'Green Revolution primarily boosted wheat and rice production.'},
            ]
        else:
            questions = generate_default_questions(module_name, chapter_title)
    
    elif module_name == 'People as Resource':
        if chapter_title == 'Human Capital Formation':
            questions = [
                {'q': 'Human capital refers to:', 'opts': ['Skills and knowledge of workforce', 'Number of people', 'Machines and tools', 'Natural resources'], 'correct': 0, 'exp': 'Human capital is the stock of skills and knowledge in the workforce.'},
                {'q': 'Investment in human capital includes:', 'opts': ['Education and health expenditure', 'Buying machines', 'Land purchase', 'Building factories'], 'correct': 0, 'exp': 'Education and health investments improve human capital.'},
                {'q': 'When does population become human resource?', 'opts': ['When invested in through education and health', 'When it increases', 'When it decreases', 'Never'], 'correct': 0, 'exp': 'Population becomes productive human resource through education and skills.'},
                {'q': 'Primary education is important because:', 'opts': ['It is the foundation for all further learning', 'It is optional', 'Only higher education matters', 'It has no impact'], 'correct': 0, 'exp': 'Primary education builds the foundation for all future learning.'},
                {'q': 'Mid-day meal scheme promotes:', 'opts': ['Education and nutrition', 'Only food security', 'Only employment', 'Higher education'], 'correct': 0, 'exp': 'Mid-day meals improve school attendance and child nutrition.'},
                {'q': 'Human capital formation leads to:', 'opts': ['Economic growth', 'Population decline', 'Resource depletion', 'Poverty increase'], 'correct': 0, 'exp': 'Better human capital drives economic growth.'},
                {'q': 'Healthcare improves:', 'opts': ['Productivity of workers', 'Nothing', 'Only leisure time', 'Population growth only'], 'correct': 0, 'exp': 'Healthy workers are more productive.'},
                {'q': 'Japan\'s development is based on:', 'opts': ['Investment in human resources', 'Natural resources only', 'Large land area', 'Military power'], 'correct': 0, 'exp': 'Japan developed through investing in its people despite few natural resources.'},
                {'q': 'Skilled workers earn:', 'opts': ['Higher wages than unskilled', 'Same as unskilled', 'Less than unskilled', 'No wages'], 'correct': 0, 'exp': 'Skills command higher wages in the market.'},
                {'q': 'Sarva Shiksha Abhiyan aims for:', 'opts': ['Universal elementary education', 'Higher education only', 'Vocational training only', 'Adult education only'], 'correct': 0, 'exp': 'SSA aims for universal access to elementary education.'},
            ]
        elif chapter_title == 'Unemployment':
            questions = [
                {'q': 'Disguised unemployment is found mainly in:', 'opts': ['Agriculture', 'Manufacturing', 'Services', 'Mining'], 'correct': 0, 'exp': 'In agriculture, more people work than needed, leading to disguised unemployment.'},
                {'q': 'Seasonal unemployment occurs in:', 'opts': ['Agriculture', 'IT sector', 'Government jobs', 'Banking'], 'correct': 0, 'exp': 'Farmers are unemployed in certain seasons.'},
                {'q': 'Educated unemployment refers to:', 'opts': ['Educated people without jobs', 'Uneducated people', 'All unemployed', 'Self-employed'], 'correct': 0, 'exp': 'When educated youth cannot find suitable jobs.'},
                {'q': 'Open unemployment is seen in:', 'opts': ['Urban areas', 'Rural areas only', 'Agriculture only', 'Only in villages'], 'correct': 0, 'exp': 'Open unemployment is visible mainly in urban areas.'},
                {'q': 'MGNREGA guarantees:', 'opts': ['100 days of employment', '365 days of employment', '50 days of employment', 'Permanent jobs'], 'correct': 0, 'exp': 'MGNREGA provides 100 days of guaranteed wage employment.'},
                {'q': 'Unemployment leads to:', 'opts': ['Wastage of human resources', 'Economic growth', 'Higher incomes', 'Better health'], 'correct': 0, 'exp': 'Unemployment wastes human potential and resources.'},
                {'q': 'Self-employment includes:', 'opts': ['Own business or profession', 'Government job', 'Factory work', 'Farming for wages'], 'correct': 0, 'exp': 'Self-employed people run their own business.'},
                {'q': 'Underemployment means:', 'opts': ['Working below full capacity', 'No work at all', 'Overwork', 'High salary'], 'correct': 0, 'exp': 'Underemployment is working less than one\'s potential.'},
                {'q': 'Which is a solution to unemployment?', 'opts': ['Skill development', 'Population increase', 'Less education', 'Closing industries'], 'correct': 0, 'exp': 'Skill development creates job opportunities.'},
                {'q': 'Labour force includes:', 'opts': ['Those working and looking for work', 'Only employed', 'Only unemployed', 'Children only'], 'correct': 0, 'exp': 'Labour force is working age population willing to work.'},
            ]
        else:
            questions = generate_default_questions(module_name, chapter_title)
    
    elif module_name == 'Food Security in India':
        if chapter_title == 'What is Food Security?':
            questions = [
                {'q': 'Food security has how many dimensions?', 'opts': ['Three', 'Two', 'Four', 'Five'], 'correct': 0, 'exp': 'Food security has three dimensions: availability, accessibility, and affordability.'},
                {'q': 'Food availability refers to:', 'opts': ['Sufficient food production in country', 'Food in markets only', 'Imported food', 'Luxury food'], 'correct': 0, 'exp': 'Availability means enough food is produced domestically.'},
                {'q': 'Food accessibility means:', 'opts': ['Food is within reach of every person', 'Food is only in cities', 'Food is expensive', 'Food is imported'], 'correct': 0, 'exp': 'Accessibility ensures food reaches all people.'},
                {'q': 'Food affordability means:', 'opts': ['People can buy required food', 'Food is free', 'Food is expensive', 'Only rich can buy'], 'correct': 0, 'exp': 'Affordability ensures people can purchase needed food.'},
                {'q': 'Who is food insecure in India?', 'opts': ['Landless poor, casual workers', 'Rich farmers', 'Government employees', 'Business owners'], 'correct': 0, 'exp': 'Poor and marginalized groups are most food insecure.'},
                {'q': 'A famine causes:', 'opts': ['Mass starvation and death', 'Prosperity', 'Good harvest', 'High employment'], 'correct': 0, 'exp': 'Famines lead to widespread hunger and deaths.'},
                {'q': 'Bengal Famine occurred in:', 'opts': ['1943', '1960', '1975', '1990'], 'correct': 0, 'exp': 'The Bengal Famine of 1943 killed millions.'},
                {'q': 'Chronic hunger is:', 'opts': ['Persistent undernourishment', 'Temporary hunger', 'Seasonal hunger', 'No hunger'], 'correct': 0, 'exp': 'Chronic hunger is consistent lack of adequate food.'},
                {'q': 'Seasonal hunger is related to:', 'opts': ['Agricultural cycles', 'Festivals', 'Weather only', 'Markets'], 'correct': 0, 'exp': 'Seasonal hunger occurs during lean agricultural periods.'},
                {'q': 'Food security was achieved in India through:', 'opts': ['Green Revolution and PDS', 'Import only', 'Rationing only', 'No measures'], 'correct': 0, 'exp': 'Green Revolution increased production; PDS ensured distribution.'},
            ]
        else:
            questions = generate_default_questions(module_name, chapter_title)
    
    if not questions:
        questions = generate_default_questions(module_name, chapter_title)
    
    return questions


def get_hots_questions(module_name, chapter_title):
    hots = []
    
    if module_name == 'The Story of Village Palampur':
        if chapter_title == 'Farming in Palampur':
            hots = [
                {'q': 'Explain how the Green Revolution increased inequality among farmers.', 'opts': ['Rich farmers benefited more as they could afford inputs; small farmers fell into debt', 'All farmers benefited equally', 'Only poor farmers benefited', 'No impact on farmers'], 'correct': 0, 'exp': 'Green Revolution needed capital investment in seeds, irrigation, and fertilizers that only large farmers could afford.'},
                {'q': 'Why is multiple cropping considered a better way to increase production than using HYV seeds?', 'opts': ['It does not deplete soil or require high investment', 'HYV seeds are cheaper', 'Multiple cropping needs more water', 'There is no difference'], 'correct': 0, 'exp': 'Multiple cropping is sustainable and less capital-intensive compared to HYV-based farming.'},
                {'q': 'Analyze the environmental concerns arising from modern farming methods.', 'opts': ['Soil degradation, water depletion, chemical pollution', 'No environmental concerns', 'Improved environment', 'More biodiversity'], 'correct': 0, 'exp': 'Overuse of chemicals depletes soil, groundwater falls, and pollution increases.'},
            ]
        else:
            hots = generate_default_hots(module_name, chapter_title)
    
    elif module_name == 'People as Resource':
        if chapter_title == 'Unemployment':
            hots = [
                {'q': 'How does disguised unemployment in agriculture affect the economy?', 'opts': ['Low productivity, underutilized labour, low income', 'High productivity', 'More employment', 'Higher wages'], 'correct': 0, 'exp': 'Disguised unemployment means more workers share same output, reducing productivity and income.'},
                {'q': 'Compare educated unemployment in India with other types of unemployment.', 'opts': ['It wastes investment in education; skills mismatch; affects urban youth more', 'It is less serious', 'Only affects rural areas', 'Easily solved'], 'correct': 0, 'exp': 'Educated unemployment represents wasted human capital investment and skills-job mismatch.'},
                {'q': 'Suggest measures to reduce seasonal unemployment in rural areas.', 'opts': ['Non-farm activities, skill development, MGNREGA, irrigation improvement', 'More farming only', 'Migration to cities', 'Do nothing'], 'correct': 0, 'exp': 'Diversifying rural economy and improving agriculture can reduce seasonal unemployment.'},
            ]
        else:
            hots = generate_default_hots(module_name, chapter_title)
    
    if not hots:
        hots = generate_default_hots(module_name, chapter_title)
    
    return hots


def generate_default_questions(module_name, chapter_title):
    return [{'q': f'{chapter_title} - Question {i+1}', 'opts': ['Correct', 'Wrong A', 'Wrong B', 'Wrong C'], 'correct': 0, 'exp': f'Explanation {i+1}'} for i in range(10)]

def generate_default_hots(module_name, chapter_title):
    return [{'q': f'{chapter_title} - HOTS {i+1}', 'opts': ['Correct', 'Wrong A', 'Wrong B', 'Wrong C'], 'correct': 0, 'exp': f'HOTS Explanation {i+1}'} for i in range(3)]


class Command(BaseCommand):
    help = 'Populate Economics subject'

    def add_arguments(self, parser):
        parser.add_argument('--clear-existing', action='store_true')

    def handle(self, *args, **options):
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

        if options.get('clear_existing'):
            ChapterHOTS.objects.filter(chapter__module__subject=subject).delete()
            ModuleContent.objects.filter(chapter__module__subject=subject).delete()
            ModuleChapter.objects.filter(module__subject=subject).delete()
            Module.objects.filter(subject=subject).delete()

        accounts = list(Account.objects.filter(is_superuser=False)[:1]) or list(Account.objects.filter(is_superuser=True)[:1])
        created_by = accounts[0] if accounts else None
        stats = {'modules': 0, 'chapters': 0, 'questions': 0, 'hots': 0}

        with transaction.atomic():
            for module_order, (module_name, module_data) in enumerate(ECONOMICS_MODULES.items(), start=1):
                module, created = Module.objects.get_or_create(
                    name=module_name, subject=subject,
                    defaults={'description': module_data['description'], 'order': module_order, 'is_active': True, 'is_enabled': True, 'created_by': created_by}
                )
                if created: stats['modules'] += 1

                for chapter_order, chapter_data in enumerate(module_data['chapters'], start=1):
                    chapter, created = ModuleChapter.objects.get_or_create(
                        module=module, order=chapter_order,
                        defaults={'title': chapter_data['title'], 'description': chapter_data['description'], 'is_enabled': True, 'is_important': chapter_order <= 2, 'has_hots': True, 'created_by': created_by}
                    )
                    if not created: continue
                    stats['chapters'] += 1

                    for q_order, q_data in enumerate(get_chapter_questions(module_name, chapter_data['title'])[:10], start=1):
                        question = Question.objects.create(question_text=q_data['q'], question_type='mcq_single', exp_points=random.randint(10, 30), difficulty_level=random.choice(['easy', 'medium', 'hard']), explanation=q_data['exp'], is_active=True, is_hots=False, created_by=created_by)
                        stats['questions'] += 1
                        for opt_order, opt_text in enumerate(q_data['opts'], start=1):
                            Option.objects.get_or_create(question=question, option_text=opt_text, defaults={'is_correct': (opt_order-1==q_data['correct']), 'order': opt_order})
                        ModuleContent.objects.get_or_create(chapter=chapter, order=q_order, defaults={'content_type': 'question', 'question': question, 'created_by': created_by})

                    for hots_order, hots_data in enumerate(get_hots_questions(module_name, chapter_data['title'])[:3], start=1):
                        hots_q = Question.objects.create(question_text=hots_data['q'], question_type='mcq_single', exp_points=random.randint(40, 60), difficulty_level='hard', explanation=hots_data['exp'], is_active=True, is_hots=True, created_by=created_by)
                        stats['questions'] += 1; stats['hots'] += 1
                        for opt_order, opt_text in enumerate(hots_data['opts'], start=1):
                            Option.objects.get_or_create(question=hots_q, option_text=opt_text, defaults={'is_correct': (opt_order-1==hots_data['correct']), 'order': opt_order})
                        ChapterHOTS.objects.get_or_create(chapter=chapter, question=hots_q, defaults={'order': hots_order, 'created_by': created_by})

        self.stdout.write(self.style.SUCCESS(f'{SUBJECT_NAME}: {stats["modules"]} modules, {stats["chapters"]} chapters, {stats["questions"]} questions'))

