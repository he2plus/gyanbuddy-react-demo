"""
Django management command to populate Civics subject with:
- 5 modules covering Class 9 Civics/Political Science topics
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

SUBJECT_NAME = 'Civics'

CIVICS_MODULES = {
    'What is Democracy? Why Democracy?': {
        'description': 'Understanding democracy and its features',
        'chapters': [
            {'title': 'What is Democracy?', 'description': 'Definition and meaning of democracy'},
            {'title': 'Features of Democracy', 'description': 'Key characteristics of democratic systems'},
            {'title': 'Why Democracy?', 'description': 'Arguments in favor of democracy'},
            {'title': 'Arguments Against Democracy', 'description': 'Criticism and challenges of democracy'},
            {'title': 'Broader Meaning of Democracy', 'description': 'Democracy beyond elections'},
            {'title': 'Types of Democracy', 'description': 'Direct and representative democracy'},
        ]
    },
    'Constitutional Design': {
        'description': 'Making of the Indian Constitution',
        'chapters': [
            {'title': 'Need for a Constitution', 'description': 'Why countries need constitutions'},
            {'title': 'Making of Indian Constitution', 'description': 'Constituent Assembly and its work'},
            {'title': 'Guiding Values of Constitution', 'description': 'Ideals in the Preamble'},
            {'title': 'The Preamble', 'description': 'Philosophy of the Constitution'},
            {'title': 'Fundamental Rights', 'description': 'Rights guaranteed to citizens'},
            {'title': 'Directive Principles', 'description': 'Guidelines for government policy'},
        ]
    },
    'Electoral Politics': {
        'description': 'Elections and voting in democracy',
        'chapters': [
            {'title': 'Why Elections?', 'description': 'Role of elections in democracy'},
            {'title': 'Electoral System in India', 'description': 'How elections work in India'},
            {'title': 'Political Parties', 'description': 'Role and types of political parties'},
            {'title': 'Election Commission', 'description': 'Independent body conducting elections'},
            {'title': 'Electoral Reforms', 'description': 'Challenges and improvements needed'},
            {'title': 'Participation of People', 'description': 'Voter turnout and civic engagement'},
        ]
    },
    'Working of Institutions': {
        'description': 'How government institutions function',
        'chapters': [
            {'title': 'How is a Major Policy Decision Made?', 'description': 'Decision-making process'},
            {'title': 'Parliament', 'description': 'Structure and functions of Parliament'},
            {'title': 'Political Executive', 'description': 'Prime Minister and Council of Ministers'},
            {'title': 'The Judiciary', 'description': 'Role of courts and judicial system'},
            {'title': 'Relationship Between Institutions', 'description': 'Separation and balance of powers'},
            {'title': 'Need for Political Institutions', 'description': 'Why institutions matter'},
        ]
    },
    'Democratic Rights': {
        'description': 'Rights of citizens in a democracy',
        'chapters': [
            {'title': 'Life Without Rights', 'description': 'Importance of rights'},
            {'title': 'Rights in Indian Constitution', 'description': 'Fundamental Rights overview'},
            {'title': 'Right to Equality', 'description': 'Equality before law'},
            {'title': 'Right to Freedom', 'description': 'Various freedoms guaranteed'},
            {'title': 'Right Against Exploitation', 'description': 'Protection from exploitation'},
            {'title': 'Right to Constitutional Remedies', 'description': 'Enforcing fundamental rights'},
        ]
    },
}


def get_chapter_questions(module_name, chapter_title):
    questions = []
    
    if module_name == 'What is Democracy? Why Democracy?':
        if chapter_title == 'What is Democracy?':
            questions = [
                {'q': 'Democracy is a form of government in which:', 'opts': ['People rule themselves through elected representatives', 'King rules the country', 'Military governs', 'Rich people decide'], 'correct': 0, 'exp': 'Democracy means rule by the people.'},
                {'q': 'The word democracy comes from:', 'opts': ['Greek words demos and kratia', 'Latin words', 'French words', 'English words'], 'correct': 0, 'exp': 'Democracy comes from Greek: demos (people) + kratia (rule).'},
                {'q': 'Which is NOT a feature of democracy?', 'opts': ['Hereditary rulers', 'Free and fair elections', 'Multiple parties', 'Universal adult franchise'], 'correct': 0, 'exp': 'Hereditary rule is a feature of monarchy, not democracy.'},
                {'q': 'In a democracy, the final decision-making power rests with:', 'opts': ['People elected by citizens', 'Army chief', 'King', 'Business leaders'], 'correct': 0, 'exp': 'In democracy, elected representatives make decisions.'},
                {'q': 'One person, one vote means:', 'opts': ['Each citizen has equal voting power', 'Only one person can vote', 'Vote once in lifetime', 'Only men can vote'], 'correct': 0, 'exp': 'Every citizen\'s vote has equal value.'},
                {'q': 'Which country is known as the birthplace of democracy?', 'opts': ['Greece (Athens)', 'USA', 'UK', 'France'], 'correct': 0, 'exp': 'Ancient Athens is considered the birthplace of democracy.'},
                {'q': 'Universal adult franchise means:', 'opts': ['All adult citizens have right to vote', 'Only educated can vote', 'Only property owners vote', 'Only men can vote'], 'correct': 0, 'exp': 'All adults regardless of class, caste, or gender can vote.'},
                {'q': 'A government is democratic only when:', 'opts': ['It is elected by the people', 'It has a king', 'It has an army', 'It is rich'], 'correct': 0, 'exp': 'Democratic government must be chosen through elections.'},
                {'q': 'In democracy, opposition parties are:', 'opts': ['Essential for healthy democracy', 'Not allowed', 'Put in jail', 'Ignored always'], 'correct': 0, 'exp': 'Opposition is crucial for checks and balances in democracy.'},
                {'q': 'Which is an example of non-democratic government?', 'opts': ['Dictatorship', 'Constitutional monarchy', 'Republic', 'Parliamentary system'], 'correct': 0, 'exp': 'Dictatorship is ruled by one person without elections.'},
            ]
        elif chapter_title == 'Features of Democracy':
            questions = [
                {'q': 'Major decisions in democracy are made by:', 'opts': ['Elected representatives', 'Army generals', 'Religious leaders', 'Business owners'], 'correct': 0, 'exp': 'Elected representatives make decisions in a democracy.'},
                {'q': 'Free and fair elections mean:', 'opts': ['Elections without fear or fraud', 'Elections with one candidate', 'Elections for rich only', 'No elections'], 'correct': 0, 'exp': 'Fair elections allow genuine choice without manipulation.'},
                {'q': 'Rule of law means:', 'opts': ['Everyone is equal before law', 'Rulers are above law', 'Law applies to poor only', 'No laws exist'], 'correct': 0, 'exp': 'In democracy, law applies equally to all, including rulers.'},
                {'q': 'Freedom of expression in democracy allows:', 'opts': ['Citizens to criticize government', 'Only praising government', 'Silence on political matters', 'Violence against opponents'], 'correct': 0, 'exp': 'Citizens can freely express opinions, including criticism.'},
                {'q': 'Multi-party system ensures:', 'opts': ['Competition and choice for voters', 'Only one party rules', 'Military control', 'No elections'], 'correct': 0, 'exp': 'Multiple parties give voters real choices.'},
                {'q': 'Accountability in democracy means:', 'opts': ['Government is answerable to people', 'People answer to government', 'No one is responsible', 'Only army is responsible'], 'correct': 0, 'exp': 'Elected representatives must answer for their actions.'},
                {'q': 'Transparency in government means:', 'opts': ['Government functioning is open to scrutiny', 'Secret decisions', 'Hidden accounts', 'No public information'], 'correct': 0, 'exp': 'Democratic governments must be open about their actions.'},
                {'q': 'Which is NOT a democratic feature?', 'opts': ['Censorship of media', 'Free press', 'Independent judiciary', 'Universal franchise'], 'correct': 0, 'exp': 'Censorship restricts freedom, which is undemocratic.'},
                {'q': 'Democracy allows people to:', 'opts': ['Change government through elections', 'Never change government', 'Overthrow by violence', 'Bribe officials'], 'correct': 0, 'exp': 'Elections provide peaceful means to change government.'},
                {'q': 'Fundamental rights in democracy:', 'opts': ['Protect citizens from government abuse', 'Give unlimited power to government', 'Benefit only rulers', 'Do not exist'], 'correct': 0, 'exp': 'Rights protect citizens and limit government power.'},
            ]
        else:
            questions = generate_default_questions(module_name, chapter_title)
    
    elif module_name == 'Constitutional Design':
        if chapter_title == 'Making of Indian Constitution':
            questions = [
                {'q': 'The Constituent Assembly was formed in:', 'opts': ['1946', '1947', '1950', '1942'], 'correct': 0, 'exp': 'Constituent Assembly was formed in 1946.'},
                {'q': 'Who was the Chairman of the Drafting Committee?', 'opts': ['Dr. B.R. Ambedkar', 'Jawaharlal Nehru', 'Mahatma Gandhi', 'Sardar Patel'], 'correct': 0, 'exp': 'Dr. B.R. Ambedkar chaired the Drafting Committee.'},
                {'q': 'The Indian Constitution was adopted on:', 'opts': ['26 November 1949', '26 January 1950', '15 August 1947', '26 January 1949'], 'correct': 0, 'exp': 'Constitution was adopted on 26 November 1949.'},
                {'q': 'Republic Day is celebrated on:', 'opts': ['26 January', '26 November', '15 August', '2 October'], 'correct': 0, 'exp': 'Constitution came into effect on 26 January 1950.'},
                {'q': 'The Constituent Assembly had how many members approximately?', 'opts': ['299', '500', '150', '100'], 'correct': 0, 'exp': 'Constituent Assembly had about 299 members.'},
                {'q': 'The making of Constitution took approximately:', 'opts': ['3 years', '5 years', '1 year', '10 years'], 'correct': 0, 'exp': 'Constitution was drafted over nearly 3 years.'},
                {'q': 'The Constitution of India borrowed from:', 'opts': ['Many countries including UK, USA, Ireland', 'Only UK', 'Only USA', 'No other country'], 'correct': 0, 'exp': 'India borrowed best features from various constitutions.'},
                {'q': 'Cabinet Mission to India came in:', 'opts': ['1946', '1947', '1945', '1948'], 'correct': 0, 'exp': 'Cabinet Mission arrived in India in 1946.'},
                {'q': 'Who is called the Father of Indian Constitution?', 'opts': ['Dr. B.R. Ambedkar', 'Jawaharlal Nehru', 'Mahatma Gandhi', 'Rajendra Prasad'], 'correct': 0, 'exp': 'Dr. Ambedkar is revered as Father of the Constitution.'},
                {'q': 'First President of Constituent Assembly was:', 'opts': ['Dr. Rajendra Prasad', 'Dr. Ambedkar', 'Nehru', 'Patel'], 'correct': 0, 'exp': 'Dr. Rajendra Prasad was elected President of Constituent Assembly.'},
            ]
        elif chapter_title == 'The Preamble':
            questions = [
                {'q': 'The Preamble declares India as:', 'opts': ['Sovereign, Socialist, Secular, Democratic Republic', 'Kingdom', 'Colony', 'Federation only'], 'correct': 0, 'exp': 'Preamble describes India\'s basic character.'},
                {'q': 'Sovereign means:', 'opts': ['Supreme and independent authority', 'Dependent on others', 'Part of another country', 'Colony'], 'correct': 0, 'exp': 'Sovereign means India is independent and supreme.'},
                {'q': 'Secular means:', 'opts': ['No official state religion, all religions equal', 'One official religion', 'No religions allowed', 'Only Hindu nation'], 'correct': 0, 'exp': 'Secular means all religions are treated equally.'},
                {'q': '"Socialist" and "Secular" were added to Preamble by:', 'opts': ['42nd Amendment', '44th Amendment', '1st Amendment', 'Original Constitution'], 'correct': 0, 'exp': '42nd Amendment (1976) added these words.'},
                {'q': 'The Preamble begins with:', 'opts': ['We, the people of India', 'The Government of India', 'The President of India', 'The Parliament'], 'correct': 0, 'exp': '"We, the people" shows people\'s sovereignty.'},
                {'q': 'Justice in Preamble includes:', 'opts': ['Social, economic and political justice', 'Only legal justice', 'Only economic', 'Only political'], 'correct': 0, 'exp': 'Preamble promises comprehensive justice.'},
                {'q': 'Liberty in Preamble is of:', 'opts': ['Thought, expression, belief, faith and worship', 'Only speech', 'Only movement', 'Only religion'], 'correct': 0, 'exp': 'Various liberties are guaranteed.'},
                {'q': 'Equality in Preamble means:', 'opts': ['Equality of status and opportunity', 'All earn same', 'All same height', 'All same age'], 'correct': 0, 'exp': 'Equal status and opportunity for all citizens.'},
                {'q': 'Fraternity in Preamble promotes:', 'opts': ['Brotherhood and unity', 'Division', 'Separation', 'Discrimination'], 'correct': 0, 'exp': 'Fraternity means brotherhood among citizens.'},
                {'q': 'The Preamble is sometimes called:', 'opts': ['Soul of the Constitution', 'Body of Constitution', 'Heart only', 'Nothing important'], 'correct': 0, 'exp': 'Preamble reflects the philosophy and soul of Constitution.'},
            ]
        else:
            questions = generate_default_questions(module_name, chapter_title)
    
    elif module_name == 'Democratic Rights':
        if chapter_title == 'Right to Equality':
            questions = [
                {'q': 'Article 14 guarantees:', 'opts': ['Equality before law', 'Right to vote', 'Freedom of speech', 'Right to property'], 'correct': 0, 'exp': 'Article 14 provides equality before law to all.'},
                {'q': 'Prohibition of discrimination on grounds of religion, race, caste, sex or place of birth is in:', 'opts': ['Article 15', 'Article 14', 'Article 16', 'Article 17'], 'correct': 0, 'exp': 'Article 15 prohibits discrimination.'},
                {'q': 'Equal opportunity in public employment is guaranteed by:', 'opts': ['Article 16', 'Article 14', 'Article 15', 'Article 18'], 'correct': 0, 'exp': 'Article 16 ensures equal opportunity in government jobs.'},
                {'q': 'Untouchability is abolished by:', 'opts': ['Article 17', 'Article 14', 'Article 15', 'Article 16'], 'correct': 0, 'exp': 'Article 17 abolishes untouchability.'},
                {'q': 'Titles (like Sir, Rai Bahadur) are abolished by:', 'opts': ['Article 18', 'Article 17', 'Article 14', 'Article 19'], 'correct': 0, 'exp': 'Article 18 abolishes titles.'},
                {'q': 'Right to Equality includes:', 'opts': ['Articles 14 to 18', 'Only Article 14', 'Articles 19-22', 'Article 21 only'], 'correct': 0, 'exp': 'Articles 14-18 comprise Right to Equality.'},
                {'q': 'Equal protection of laws means:', 'opts': ['Laws apply equally to all in same situation', 'Different laws for everyone', 'No laws for anyone', 'Laws only for poor'], 'correct': 0, 'exp': 'Equal circumstances get equal legal treatment.'},
                {'q': 'Reservation is allowed for:', 'opts': ['Backward classes for their upliftment', 'Rich people only', 'All castes equally', 'No one'], 'correct': 0, 'exp': 'Constitution allows positive discrimination for disadvantaged groups.'},
                {'q': 'Practice of untouchability is:', 'opts': ['A punishable offense', 'Legal in villages', 'Allowed sometimes', 'Not mentioned'], 'correct': 0, 'exp': 'Practicing untouchability is a crime under law.'},
                {'q': 'Any citizen can access public places due to:', 'opts': ['Article 15(2)', 'Article 14', 'Article 17', 'Article 18'], 'correct': 0, 'exp': 'Article 15(2) prohibits discrimination in public places.'},
            ]
        elif chapter_title == 'Right to Constitutional Remedies':
            questions = [
                {'q': 'Right to Constitutional Remedies is in:', 'opts': ['Article 32', 'Article 21', 'Article 19', 'Article 14'], 'correct': 0, 'exp': 'Article 32 provides right to approach Supreme Court.'},
                {'q': 'Dr. Ambedkar called Article 32:', 'opts': ['Heart and soul of Constitution', 'Body of Constitution', 'Not important', 'Optional right'], 'correct': 0, 'exp': 'Ambedkar considered it most important for enforcing rights.'},
                {'q': 'Habeas Corpus means:', 'opts': ['Produce the body (person)', 'What is your authority', 'Be informed', 'Command to do'], 'correct': 0, 'exp': 'Habeas Corpus protects personal liberty.'},
                {'q': 'Mandamus means:', 'opts': ['We command', 'Produce the body', 'What is your authority', 'Be informed'], 'correct': 0, 'exp': 'Mandamus orders authorities to perform their duty.'},
                {'q': 'Writ of Prohibition is issued to:', 'opts': ['Stop lower court from exceeding jurisdiction', 'Order someone to appear', 'Release a person', 'Transfer a case'], 'correct': 0, 'exp': 'Prohibition prevents lower courts from overstepping.'},
                {'q': 'Quo Warranto means:', 'opts': ['By what authority', 'We command', 'Be informed', 'Produce the body'], 'correct': 0, 'exp': 'Quo Warranto questions authority to hold office.'},
                {'q': 'Certiorari is issued to:', 'opts': ['Quash orders of lower courts', 'Release a person', 'Order public duty', 'Question authority'], 'correct': 0, 'exp': 'Certiorari brings case to higher court to review.'},
                {'q': 'Who can issue writs under Article 32?', 'opts': ['Supreme Court', 'High Court only', 'District Court', 'Any court'], 'correct': 0, 'exp': 'Supreme Court issues writs under Article 32.'},
                {'q': 'High Courts can issue writs under:', 'opts': ['Article 226', 'Article 32', 'Article 21', 'Article 14'], 'correct': 0, 'exp': 'Article 226 gives writ jurisdiction to High Courts.'},
                {'q': 'Article 32 can be suspended:', 'opts': ['During Emergency', 'Never', 'Always', 'By President anytime'], 'correct': 0, 'exp': 'Article 32 can be suspended during national emergency.'},
            ]
        else:
            questions = generate_default_questions(module_name, chapter_title)
    
    elif module_name == 'Electoral Politics':
        if chapter_title == 'Why Elections?':
            questions = [
                {'q': 'Elections allow citizens to:', 'opts': ['Choose their representatives', 'Become king', 'Avoid government', 'Pay no taxes'], 'correct': 0, 'exp': 'Elections are the means to choose who governs.'},
                {'q': 'In India, general elections are held every:', 'opts': ['5 years', '4 years', '6 years', '3 years'], 'correct': 0, 'exp': 'Lok Sabha elections occur every 5 years.'},
                {'q': 'Elections ensure that:', 'opts': ['Government is accountable to people', 'Rulers stay forever', 'No change is possible', 'Only rich rule'], 'correct': 0, 'exp': 'Elections create accountability and possibility of change.'},
                {'q': 'Peaceful transfer of power happens through:', 'opts': ['Elections', 'Revolution', 'Violence', 'Family succession'], 'correct': 0, 'exp': 'Elections allow peaceful change of government.'},
                {'q': 'Minimum voting age in India is:', 'opts': ['18 years', '21 years', '25 years', '16 years'], 'correct': 0, 'exp': 'Any citizen 18 or above can vote.'},
                {'q': 'Elections should be:', 'opts': ['Free and fair', 'Controlled by ruling party', 'Secret from public', 'Only for some'], 'correct': 0, 'exp': 'Democratic elections must be free and fair.'},
                {'q': 'Without elections, democracy would:', 'opts': ['Not exist', 'Be stronger', 'Remain same', 'Improve'], 'correct': 0, 'exp': 'Elections are essential for democracy.'},
                {'q': 'Secret ballot means:', 'opts': ['Vote is confidential', 'Vote is public', 'No voting', 'King decides'], 'correct': 0, 'exp': 'Secret ballot protects voter\'s choice from pressure.'},
                {'q': 'Electoral roll is:', 'opts': ['List of eligible voters', 'List of candidates', 'List of winners', 'Budget document'], 'correct': 0, 'exp': 'Electoral roll contains names of registered voters.'},
                {'q': 'By-elections are held when:', 'opts': ['A seat becomes vacant mid-term', 'Every year', 'With general elections', 'Never'], 'correct': 0, 'exp': 'By-elections fill vacant seats between general elections.'},
            ]
        else:
            questions = generate_default_questions(module_name, chapter_title)
    
    if not questions:
        questions = generate_default_questions(module_name, chapter_title)
    
    return questions


def get_hots_questions(module_name, chapter_title):
    hots = []
    
    if module_name == 'What is Democracy? Why Democracy?':
        if chapter_title == 'What is Democracy?':
            hots = [
                {'q': 'Explain why democracy is considered better than other forms of government despite its limitations.', 'opts': ['It respects dignity, allows peaceful change, promotes equality, and is accountable', 'It is faster', 'It has no problems', 'Other forms are illegal'], 'correct': 0, 'exp': 'Democracy values human dignity, provides accountability, and allows peaceful resolution of conflicts.'},
                {'q': 'Analyze why some countries that hold elections may still not be truly democratic.', 'opts': ['Elections may not be free/fair; opposition suppressed; media controlled; rights violated', 'All elections make democracy', 'Number of parties matters only', 'Voting percentage decides'], 'correct': 0, 'exp': 'True democracy requires free elections, free speech, and protection of rights.'},
                {'q': 'Compare democracy and dictatorship in terms of decision-making and citizen participation.', 'opts': ['Democracy involves citizens; dictatorship has no citizen role; democracy is slower but inclusive', 'Both are same', 'Dictatorship is always better', 'Democracy excludes people'], 'correct': 0, 'exp': 'Democracy includes people in governance while dictatorship concentrates power.'},
            ]
        else:
            hots = generate_default_hots(module_name, chapter_title)
    
    elif module_name == 'Constitutional Design':
        if chapter_title == 'The Preamble':
            hots = [
                {'q': 'Explain how the Preamble reflects the aspirations of the Indian people.', 'opts': ['It promises justice, liberty, equality, fraternity - addressing colonial oppression and social evils', 'It is just an introduction', 'It has no meaning', 'Only for government'], 'correct': 0, 'exp': 'Preamble captured the dreams of independent India - freedom from colonial rule and social discrimination.'},
                {'q': 'Discuss whether India has achieved the ideals mentioned in the Preamble.', 'opts': ['Partial success - formal equality exists but social and economic gaps remain', 'Complete success', 'Complete failure', 'Preamble is not implemented'], 'correct': 0, 'exp': 'While legal frameworks exist, social and economic inequalities persist.'},
                {'q': 'Why is the Preamble considered the key to understanding the Constitution?', 'opts': ['It contains the philosophy, objectives and guiding principles of the entire Constitution', 'It is the longest part', 'It lists all laws', 'It is mandatory to read'], 'correct': 0, 'exp': 'Preamble encapsulates the essence and objectives of the Constitution.'},
            ]
        else:
            hots = generate_default_hots(module_name, chapter_title)
    
    elif module_name == 'Democratic Rights':
        if chapter_title == 'Right to Constitutional Remedies':
            hots = [
                {'q': 'Why did Dr. Ambedkar call the Right to Constitutional Remedies the "heart and soul" of the Constitution?', 'opts': ['Without it, other rights would be meaningless as there would be no way to enforce them', 'It is the longest article', 'It gives more power', 'It was his favorite'], 'correct': 0, 'exp': 'This right makes all other rights enforceable through courts.'},
                {'q': 'Explain how Public Interest Litigation (PIL) has strengthened the Right to Constitutional Remedies.', 'opts': ['PIL allows any citizen to approach courts for public cause, expanding access to justice', 'PIL has weakened courts', 'PIL is not related', 'PIL is only for rich'], 'correct': 0, 'exp': 'PIL democratized access to justice, allowing anyone to raise issues affecting public interest.'},
                {'q': 'What would happen if Article 32 did not exist in the Constitution?', 'opts': ['Fundamental Rights would become paper rights with no enforcement mechanism', 'Nothing would change', 'Other articles would work', 'Police would enforce'], 'correct': 0, 'exp': 'Without enforcement mechanism, rights would be theoretical, not practical.'},
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
    help = 'Populate Civics subject'

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
            for module_order, (module_name, module_data) in enumerate(CIVICS_MODULES.items(), start=1):
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

