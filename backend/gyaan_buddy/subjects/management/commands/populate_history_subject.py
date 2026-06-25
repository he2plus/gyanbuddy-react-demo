"""
Django management command to populate History subject with:
- 5 modules covering Class 9 History topics
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

SUBJECT_NAME = 'History'

HISTORY_MODULES = {
    'French Revolution': {
        'description': 'Study of the French Revolution and its impact on world history',
        'chapters': [
            {'title': 'French Society During the Late 18th Century', 'description': 'Social structure and estates system'},
            {'title': 'The Outbreak of the Revolution', 'description': 'Events leading to the revolution'},
            {'title': 'France Becomes a Constitutional Monarchy', 'description': 'Formation of National Assembly'},
            {'title': 'France Abolishes Monarchy', 'description': 'Establishment of republic and reign of terror'},
            {'title': 'Did Women Have a Revolution?', 'description': 'Role of women in the French Revolution'},
            {'title': 'The Abolition of Slavery', 'description': 'End of slavery in French colonies'},
        ]
    },
    'Socialism in Europe and the Russian Revolution': {
        'description': 'Rise of socialism and the Russian Revolution of 1917',
        'chapters': [
            {'title': 'The Age of Social Change', 'description': 'Liberals, radicals and conservatives'},
            {'title': 'The Coming of Socialism', 'description': 'Ideas of Karl Marx and socialism'},
            {'title': 'The Russian Revolution', 'description': 'February and October revolutions'},
            {'title': 'The Civil War', 'description': 'Conflict between Bolsheviks and opposition'},
            {'title': 'Making of a Socialist Society', 'description': 'Soviet state and economy'},
            {'title': 'Global Impact of Russian Revolution', 'description': 'Spread of communist ideas'},
        ]
    },
    'Nazism and the Rise of Hitler': {
        'description': 'Study of Nazi Germany and World War II',
        'chapters': [
            {'title': 'Birth of Weimar Republic', 'description': 'Germany after World War I'},
            {'title': 'Hitler\'s Rise to Power', 'description': 'Nazi Party and Hitler\'s ascent'},
            {'title': 'The Nazi Worldview', 'description': 'Ideology and propaganda'},
            {'title': 'Youth in Nazi Germany', 'description': 'Education and youth organizations'},
            {'title': 'The Nazi Cult of Motherhood', 'description': 'Women in Nazi Germany'},
            {'title': 'The Holocaust', 'description': 'Persecution and genocide'},
        ]
    },
    'Forest Society and Colonialism': {
        'description': 'Impact of colonialism on forest communities',
        'chapters': [
            {'title': 'Why Deforestation?', 'description': 'Colonial need for timber and land'},
            {'title': 'The Rise of Commercial Forestry', 'description': 'Scientific forestry and forest acts'},
            {'title': 'Rebellion in the Forest', 'description': 'Forest movements and resistance'},
            {'title': 'Forest Transformations in Java', 'description': 'Dutch colonial policies'},
            {'title': 'Samin\'s Challenge', 'description': 'Resistance movements in Java'},
            {'title': 'War and Deforestation', 'description': 'Impact of wars on forests'},
        ]
    },
    'Pastoralists in the Modern World': {
        'description': 'Life and challenges of pastoral communities',
        'chapters': [
            {'title': 'Pastoral Nomads and Their Movements', 'description': 'Seasonal migration patterns'},
            {'title': 'Colonial Rule and Pastoral Life', 'description': 'Impact of colonial policies'},
            {'title': 'Pastoralism in Africa', 'description': 'African pastoral communities'},
            {'title': 'The Maasai Community', 'description': 'Life of Maasai pastoralists'},
            {'title': 'Impact of New Laws', 'description': 'Forest acts and pastoral life'},
            {'title': 'Pastoralists Today', 'description': 'Modern challenges and adaptations'},
        ]
    },
}


def get_chapter_questions(module_name, chapter_title):
    """Generate 10 questions for a chapter."""
    questions = []
    
    if module_name == 'French Revolution':
        if chapter_title == 'French Society During the Late 18th Century':
            questions = [
                {'q': 'French society was divided into how many estates?', 'opts': ['Three', 'Two', 'Four', 'Five'], 'correct': 0, 'exp': 'French society was divided into three estates: Clergy, Nobility, and Common people.'},
                {'q': 'Which estate paid all the taxes?', 'opts': ['Third Estate', 'First Estate', 'Second Estate', 'All estates'], 'correct': 0, 'exp': 'Only the Third Estate paid taxes. Clergy and nobility were exempt.'},
                {'q': 'The First Estate comprised of:', 'opts': ['Clergy', 'Nobility', 'Peasants', 'Merchants'], 'correct': 0, 'exp': 'The First Estate was made up of the clergy.'},
                {'q': 'The currency of France during revolution was:', 'opts': ['Livre', 'Franc', 'Euro', 'Dollar'], 'correct': 0, 'exp': 'Livre was the French currency before the revolution.'},
                {'q': 'The tax paid to the church was called:', 'opts': ['Tithe', 'Taille', 'Taxes', 'Tribute'], 'correct': 0, 'exp': 'Tithe was a religious tax paid to the church.'},
                {'q': 'Who were the members of the Third Estate?', 'opts': ['Peasants, artisans, merchants', 'Only peasants', 'Only merchants', 'Nobles'], 'correct': 0, 'exp': 'Third Estate included all common people - peasants, artisans, and merchants.'},
                {'q': 'The direct tax paid to the state was called:', 'opts': ['Taille', 'Tithe', 'Feudal dues', 'None'], 'correct': 0, 'exp': 'Taille was the direct tax paid to the state.'},
                {'q': 'What percentage of population belonged to Third Estate?', 'opts': ['About 97%', 'About 50%', 'About 75%', 'About 25%'], 'correct': 0, 'exp': 'The vast majority (about 97%) belonged to the Third Estate.'},
                {'q': 'The system of indirect taxes was called:', 'opts': ['Gabelle', 'Tithe', 'Taille', 'Livre'], 'correct': 0, 'exp': 'Gabelle was the salt tax, part of indirect taxes.'},
                {'q': 'King of France during the Revolution was:', 'opts': ['Louis XVI', 'Louis XIV', 'Napoleon', 'Charles I'], 'correct': 0, 'exp': 'Louis XVI was the king when the French Revolution began.'},
            ]
        elif chapter_title == 'The Outbreak of the Revolution':
            questions = [
                {'q': 'When did the French Revolution begin?', 'opts': ['1789', '1776', '1799', '1804'], 'correct': 0, 'exp': 'The French Revolution began on July 14, 1789.'},
                {'q': 'The Bastille was:', 'opts': ['A fortress prison', 'A palace', 'A church', 'A market'], 'correct': 0, 'exp': 'Bastille was a fortress prison that symbolized royal authority.'},
                {'q': 'July 14 is celebrated in France as:', 'opts': ['Bastille Day', 'Independence Day', 'Republic Day', 'Revolution Day'], 'correct': 0, 'exp': 'July 14 is Bastille Day, marking the storming of Bastille.'},
                {'q': 'The National Assembly was formed by:', 'opts': ['Third Estate representatives', 'Clergy', 'Nobles', 'King'], 'correct': 0, 'exp': 'Third Estate representatives formed the National Assembly.'},
                {'q': 'What was the immediate cause of the Revolution?', 'opts': ['Empty treasury and food scarcity', 'War with England', 'Death of king', 'Natural disaster'], 'correct': 0, 'exp': 'Financial crisis and bread shortage triggered the revolution.'},
                {'q': 'The meeting of Estates General was called at:', 'opts': ['Versailles', 'Paris', 'Lyon', 'Marseille'], 'correct': 0, 'exp': 'Estates General met at Versailles on May 5, 1789.'},
                {'q': 'The Tennis Court Oath was taken on:', 'opts': ['June 20, 1789', 'July 14, 1789', 'August 4, 1789', 'October 5, 1789'], 'correct': 0, 'exp': 'The oath was taken on June 20, 1789 at a tennis court.'},
                {'q': 'Who wrote "The Social Contract"?', 'opts': ['Rousseau', 'Voltaire', 'Montesquieu', 'Locke'], 'correct': 0, 'exp': 'Jean-Jacques Rousseau wrote "The Social Contract".'},
                {'q': 'The slogan of French Revolution was:', 'opts': ['Liberty, Equality, Fraternity', 'Freedom and Justice', 'Unity and Progress', 'Power to People'], 'correct': 0, 'exp': 'Liberty, Equality, Fraternity was the revolutionary slogan.'},
                {'q': 'The Declaration of Rights of Man was adopted in:', 'opts': ['August 1789', 'July 1789', 'May 1789', 'June 1789'], 'correct': 0, 'exp': 'The Declaration was adopted on August 26, 1789.'},
            ]
        elif chapter_title == 'France Abolishes Monarchy':
            questions = [
                {'q': 'France became a republic in:', 'opts': ['1792', '1789', '1795', '1799'], 'correct': 0, 'exp': 'France was declared a republic on September 21, 1792.'},
                {'q': 'The Reign of Terror was led by:', 'opts': ['Robespierre', 'Napoleon', 'Louis XVI', 'Marat'], 'correct': 0, 'exp': 'Maximilien Robespierre led the Reign of Terror.'},
                {'q': 'Louis XVI was executed in:', 'opts': ['January 1793', 'July 1789', 'August 1792', 'June 1794'], 'correct': 0, 'exp': 'Louis XVI was guillotined on January 21, 1793.'},
                {'q': 'The instrument of execution was:', 'opts': ['Guillotine', 'Gallows', 'Firing squad', 'Hanging'], 'correct': 0, 'exp': 'Guillotine was the execution device used during the Terror.'},
                {'q': 'The Jacobin Club was led by:', 'opts': ['Robespierre', 'Danton', 'Marat', 'Napoleon'], 'correct': 0, 'exp': 'Robespierre was the leader of the Jacobins.'},
                {'q': 'Jacobins were also known as:', 'opts': ['Sans-culottes', 'Girondins', 'Monarchists', 'Thermidorians'], 'correct': 0, 'exp': 'Jacobins were associated with sans-culottes (without knee breeches).'},
                {'q': 'The Reign of Terror lasted from:', 'opts': ['1793-1794', '1789-1791', '1795-1799', '1792-1793'], 'correct': 0, 'exp': 'The Terror lasted from 1793 to 1794.'},
                {'q': 'Robespierre was executed in:', 'opts': ['July 1794', 'January 1793', 'August 1792', 'May 1795'], 'correct': 0, 'exp': 'Robespierre was guillotined on July 28, 1794 (Thermidor).'},
                {'q': 'The Convention ruled France from:', 'opts': ['1792-1795', '1789-1792', '1795-1799', '1799-1804'], 'correct': 0, 'exp': 'The National Convention governed from 1792 to 1795.'},
                {'q': 'The Directory ruled France from:', 'opts': ['1795-1799', '1792-1795', '1789-1792', '1799-1804'], 'correct': 0, 'exp': 'The Directory governed France from 1795 to 1799.'},
            ]
        else:
            questions = generate_default_questions(module_name, chapter_title)
    
    elif module_name == 'Nazism and the Rise of Hitler':
        if chapter_title == 'Hitler\'s Rise to Power':
            questions = [
                {'q': 'Hitler became Chancellor of Germany in:', 'opts': ['1933', '1929', '1939', '1945'], 'correct': 0, 'exp': 'Hitler was appointed Chancellor on January 30, 1933.'},
                {'q': 'The Nazi Party was also called:', 'opts': ['NSDAP', 'SPD', 'KPD', 'BDP'], 'correct': 0, 'exp': 'National Socialist German Workers Party (NSDAP) was the Nazi Party.'},
                {'q': 'The German Parliament is called:', 'opts': ['Reichstag', 'Congress', 'Parliament', 'Duma'], 'correct': 0, 'exp': 'Reichstag is the German Parliament.'},
                {'q': 'The Great Depression began in:', 'opts': ['1929', '1933', '1939', '1919'], 'correct': 0, 'exp': 'The Great Depression started with the Wall Street crash in 1929.'},
                {'q': 'The Enabling Act was passed in:', 'opts': ['1933', '1929', '1935', '1939'], 'correct': 0, 'exp': 'The Enabling Act of March 1933 gave Hitler dictatorial powers.'},
                {'q': 'Hitler\'s autobiography was called:', 'opts': ['Mein Kampf', 'Das Kapital', 'The Republic', 'My Life'], 'correct': 0, 'exp': 'Mein Kampf (My Struggle) was written by Hitler.'},
                {'q': 'The Nazi secret police was called:', 'opts': ['Gestapo', 'SS', 'SA', 'SD'], 'correct': 0, 'exp': 'Gestapo was the secret state police of Nazi Germany.'},
                {'q': 'The SS stood for:', 'opts': ['Schutzstaffel', 'Security Service', 'Storm Troopers', 'Secret Service'], 'correct': 0, 'exp': 'Schutzstaffel was Hitler\'s elite guard.'},
                {'q': 'The SA was also known as:', 'opts': ['Storm Troopers', 'Secret Police', 'Security Service', 'Regular Army'], 'correct': 0, 'exp': 'SA (Sturmabteilung) were the Storm Troopers or Brownshirts.'},
                {'q': 'World War I ended in:', 'opts': ['1918', '1914', '1919', '1939'], 'correct': 0, 'exp': 'World War I ended on November 11, 1918.'},
            ]
        elif chapter_title == 'The Holocaust':
            questions = [
                {'q': 'Holocaust refers to:', 'opts': ['Mass killing of Jews', 'World War II', 'German victory', 'Economic crisis'], 'correct': 0, 'exp': 'Holocaust was the genocide of six million Jews by Nazis.'},
                {'q': 'The "Final Solution" meant:', 'opts': ['Extermination of Jews', 'End of war', 'Peace treaty', 'Economic reform'], 'correct': 0, 'exp': 'Final Solution was the Nazi plan to exterminate all Jews.'},
                {'q': 'Concentration camps were for:', 'opts': ['Mass imprisonment and killing', 'Military training', 'Refugee shelter', 'Food storage'], 'correct': 0, 'exp': 'Concentration camps held and killed millions of people.'},
                {'q': 'Auschwitz was located in:', 'opts': ['Poland', 'Germany', 'Austria', 'France'], 'correct': 0, 'exp': 'Auschwitz was in German-occupied Poland.'},
                {'q': 'Jews were forced to wear:', 'opts': ['Yellow Star of David', 'Red cross', 'White band', 'Black triangle'], 'correct': 0, 'exp': 'Jews were forced to wear the yellow Star of David.'},
                {'q': 'The Nuremberg Laws were passed in:', 'opts': ['1935', '1933', '1939', '1941'], 'correct': 0, 'exp': 'Nuremberg Laws of 1935 stripped Jews of citizenship.'},
                {'q': 'Kristallnacht occurred in:', 'opts': ['November 1938', 'January 1933', 'September 1939', 'May 1945'], 'correct': 0, 'exp': 'Night of Broken Glass was November 9-10, 1938.'},
                {'q': 'Gas chambers used which gas?', 'opts': ['Zyklon B', 'Chlorine', 'Mustard gas', 'Carbon monoxide'], 'correct': 0, 'exp': 'Zyklon B was the primary poison gas used in chambers.'},
                {'q': 'World War II ended in:', 'opts': ['1945', '1944', '1946', '1943'], 'correct': 0, 'exp': 'WWII in Europe ended on May 8, 1945.'},
                {'q': 'Hitler died in:', 'opts': ['April 1945', 'May 1945', 'August 1945', 'September 1945'], 'correct': 0, 'exp': 'Hitler committed suicide on April 30, 1945.'},
            ]
        else:
            questions = generate_default_questions(module_name, chapter_title)
    
    if not questions:
        questions = generate_default_questions(module_name, chapter_title)
    
    return questions


def get_hots_questions(module_name, chapter_title):
    """Generate 3 HOTS questions for a chapter."""
    hots = []
    
    if module_name == 'French Revolution':
        if chapter_title == 'The Outbreak of the Revolution':
            hots = [
                {'q': 'Analyze why the French Revolution is considered a turning point in world history.', 'opts': ['It challenged absolute monarchy and feudalism, inspiring democratic movements worldwide', 'It only affected France internally', 'It was a minor political change', 'It strengthened monarchy'], 'correct': 0, 'exp': 'The Revolution challenged age-old systems and inspired revolutions globally, establishing principles of liberty and equality.'},
                {'q': 'Compare the roles of philosophers like Rousseau and Montesquieu in shaping revolutionary ideas.', 'opts': ['Rousseau promoted social contract; Montesquieu advocated separation of powers', 'Both supported absolute monarchy', 'They had no influence', 'They opposed the revolution'], 'correct': 0, 'exp': 'Rousseau\'s social contract and Montesquieu\'s separation of powers directly influenced revolutionary thought.'},
                {'q': 'Why did the Estates General fail to solve France\'s problems, leading to revolution?', 'opts': ['Unfair voting system where Third Estate was outvoted despite being 97% of population', 'The meeting was too short', 'Third Estate did not attend', 'King accepted all demands'], 'correct': 0, 'exp': 'Each estate had one vote, so First and Second estates could always outvote the Third Estate.'},
            ]
        else:
            hots = generate_default_hots(module_name, chapter_title)
    
    elif module_name == 'Nazism and the Rise of Hitler':
        if chapter_title == 'Hitler\'s Rise to Power':
            hots = [
                {'q': 'Explain how the Treaty of Versailles and Great Depression helped Hitler rise to power.', 'opts': ['They created resentment and economic hardship that Hitler exploited', 'They strengthened democracy', 'They helped Jews', 'They reduced nationalism'], 'correct': 0, 'exp': 'The humiliating treaty created resentment, and the Depression caused unemployment that Hitler blamed on Jews and Weimar government.'},
                {'q': 'Analyze the role of propaganda in establishing Nazi control over Germany.', 'opts': ['Goebbels used mass media to spread Nazi ideology and demonize enemies', 'Propaganda was not used', 'Only newspapers were used', 'It opposed Nazi ideology'], 'correct': 0, 'exp': 'Joseph Goebbels masterfully used radio, films, and rallies to indoctrinate Germans.'},
                {'q': 'Why did the Weimar Republic fail to prevent Hitler\'s rise?', 'opts': ['Economic crisis, political instability, and use of Article 48', 'It was too strong', 'People were satisfied', 'There was no opposition'], 'correct': 0, 'exp': 'The Republic faced hyperinflation, Depression, multiple governments, and constitutional weaknesses.'},
            ]
        else:
            hots = generate_default_hots(module_name, chapter_title)
    
    if not hots:
        hots = generate_default_hots(module_name, chapter_title)
    
    return hots


def generate_default_questions(module_name, chapter_title):
    questions = []
    for i in range(10):
        questions.append({
            'q': f'{chapter_title} - Question {i+1}: A historical concept question related to {module_name}.',
            'opts': [f'Correct Answer', f'Wrong Option A', f'Wrong Option B', f'Wrong Option C'],
            'correct': 0,
            'exp': f'Explanation for question {i+1} about {chapter_title}.'
        })
    return questions


def generate_default_hots(module_name, chapter_title):
    hots = []
    for i in range(3):
        hots.append({
            'q': f'{chapter_title} - HOTS {i+1}: An analytical question on {module_name}.',
            'opts': [f'Correct Analytical Answer', f'Wrong A', f'Wrong B', f'Wrong C'],
            'correct': 0,
            'exp': f'Detailed explanation for HOTS {i+1}.'
        })
    return hots


class Command(BaseCommand):
    help = 'Populate History subject with modules, chapters, questions, and HOTS'

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
            for module_order, (module_name, module_data) in enumerate(HISTORY_MODULES.items(), start=1):
                module, created = Module.objects.get_or_create(
                    name=module_name, subject=subject,
                    defaults={'description': module_data['description'], 'order': module_order,
                              'is_active': True, 'is_enabled': True, 'created_by': created_by}
                )
                if created: stats['modules'] += 1

                for chapter_order, chapter_data in enumerate(module_data['chapters'], start=1):
                    chapter, created = ModuleChapter.objects.get_or_create(
                        module=module, order=chapter_order,
                        defaults={'title': chapter_data['title'], 'description': chapter_data['description'],
                                  'is_enabled': True, 'is_important': chapter_order <= 2, 'has_hots': True, 'created_by': created_by}
                    )
                    if not created: continue
                    stats['chapters'] += 1

                    for q_order, q_data in enumerate(get_chapter_questions(module_name, chapter_data['title'])[:10], start=1):
                        question = Question.objects.create(
                            question_text=q_data['q'], question_type='mcq_single', exp_points=random.randint(10, 30),
                            difficulty_level=random.choice(['easy', 'medium', 'hard']), explanation=q_data['exp'],
                            is_active=True, is_hots=False, created_by=created_by
                        )
                        stats['questions'] += 1
                        for opt_order, opt_text in enumerate(q_data['opts'], start=1):
                            Option.objects.get_or_create(question=question, option_text=opt_text, defaults={'is_correct': (opt_order-1==q_data['correct']), 'order': opt_order})
                        ModuleContent.objects.get_or_create(chapter=chapter, order=q_order, defaults={'content_type': 'question', 'question': question, 'created_by': created_by})

                    for hots_order, hots_data in enumerate(get_hots_questions(module_name, chapter_data['title'])[:3], start=1):
                        hots_q = Question.objects.create(
                            question_text=hots_data['q'], question_type='mcq_single', exp_points=random.randint(40, 60),
                            difficulty_level='hard', explanation=hots_data['exp'], is_active=True, is_hots=True, created_by=created_by
                        )
                        stats['questions'] += 1; stats['hots'] += 1
                        for opt_order, opt_text in enumerate(hots_data['opts'], start=1):
                            Option.objects.get_or_create(question=hots_q, option_text=opt_text, defaults={'is_correct': (opt_order-1==hots_data['correct']), 'order': opt_order})
                        ChapterHOTS.objects.get_or_create(chapter=chapter, question=hots_q, defaults={'order': hots_order, 'created_by': created_by})

        self.stdout.write(self.style.SUCCESS(f'{SUBJECT_NAME}: {stats["modules"]} modules, {stats["chapters"]} chapters, {stats["questions"]} questions'))

