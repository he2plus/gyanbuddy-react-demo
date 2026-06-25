from django.test import TestCase
from django.contrib.auth import get_user_model
from .models import Subject, Module, Question, Option
from gyaan_buddy.users.models import UserModuleProgress
from gyaan_buddy.users.models import School

User = get_user_model()


class ModuleSignalsTestCase(TestCase):
    """Test cases for Module signals."""
    
    def setUp(self):
        """Set up test data."""
        self.school = School.objects.create(
            name='Test School',
            address='Test Address',
            phone='1234567890',
            email='school@test.com',
            website='https://testschool.com'
        )
        
        self.user1 = User.objects.create_user(
            username='testuser1',
            email='test1@example.com',
            password='testpass123',
            first_name='Test',
            last_name='User1',
            admission_number=1001,
            bio='Test user 1 bio',
            school=self.school
        )
        self.user2 = User.objects.create_user(
            username='testuser2',
            email='test2@example.com',
            password='testpass123',
            first_name='Test',
            last_name='User2',
            admission_number=1002,
            bio='Test user 2 bio',
            school=self.school
        )
        
        self.subject = Subject.objects.create(
            name='Test Subject',
            code='TEST',
            description='Test subject for testing',
            logo='test_logo.png',
            created_by=self.user1
        )
        
        self.module = Module.objects.create(
            name='Test Module',
            subject=self.subject,
            description='Test module for testing',
            order=1,
            is_active=True,
            is_enabled=False,
            created_by=self.user1
        )
    
    def test_create_progress_entries_on_enable(self):
        """Test that progress entries are created when module is enabled."""
        self.assertEqual(UserModuleProgress.objects.count(), 0)
        
        self.module.is_enabled = True
        self.module.save()
        
        self.assertEqual(UserModuleProgress.objects.count(), 2)
        
        user1_progress = UserModuleProgress.objects.get(account=self.user1, module=self.module)
        user2_progress = UserModuleProgress.objects.get(account=self.user2, module=self.module)
        
        self.assertEqual(user1_progress.status, 'not_started')
        self.assertEqual(user1_progress.percentage, 0)
        self.assertEqual(user2_progress.status, 'not_started')
        self.assertEqual(user2_progress.percentage, 0)
    
    def test_no_progress_entries_on_disable(self):
        """Test that no progress entries are created when module is disabled."""
        self.module.is_enabled = True
        self.module.save()
        
        initial_count = UserModuleProgress.objects.count()
        self.assertGreater(initial_count, 0)
        
        self.module.is_enabled = False
        self.module.save()
        
        self.assertEqual(UserModuleProgress.objects.count(), initial_count)

class QuestionCheckTestCase(TestCase):
    """Test cases for Question check functionality."""
    
    def setUp(self):
        """Set up test data."""
        self.school = School.objects.create(
            name='Test School',
            address='Test Address',
            phone='1234567890',
            email='school@test.com',
            website='https://testschool.com'
        )
        
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123',
            first_name='Test',
            last_name='User',
            admission_number=1001,
            bio='Test user bio',
            school=self.school
        )
        
        self.question = Question.objects.create(
            question_text='What is 2 + 2?',
            question_type='mcq_single',
            exp_points=10,
            difficulty_level='easy',
            explanation='2 + 2 equals 4',
            created_by=self.user
        )
    
    def test_exp_calculation_first_try(self):
        """Test experience calculation for first try (100% exp)."""
        initial_exp = self.user.total_exp
        
        exp_multiplier = 1.0
        base_exp = self.question.exp_points
        final_exp = int(base_exp * exp_multiplier)
        
        self.assertEqual(final_exp, 10)
        self.assertEqual(exp_multiplier, 1.0)
    
    def test_exp_calculation_second_try(self):
        """Test experience calculation for second try (75% exp)."""
        exp_multiplier = 0.75
        base_exp = self.question.exp_points
        final_exp = int(base_exp * exp_multiplier)
        
        self.assertEqual(final_exp, 7)
        self.assertEqual(exp_multiplier, 0.75)
    
    def test_exp_calculation_third_try(self):
        """Test experience calculation for third try (50% exp)."""
        exp_multiplier = 0.5
        base_exp = self.question.exp_points
        final_exp = int(base_exp * exp_multiplier)
        
        self.assertEqual(final_exp, 5)
        self.assertEqual(exp_multiplier, 0.5)
    
    def test_exp_calculation_fourth_try(self):
        """Test experience calculation for fourth try (25% exp)."""
        exp_multiplier = 0.25
        base_exp = self.question.exp_points
        final_exp = int(base_exp * exp_multiplier)
        
        self.assertEqual(final_exp, 2)
        self.assertEqual(exp_multiplier, 0.25)
    
    def test_exp_calculation_zero_tries(self):
        """Test experience calculation for zero tries (0% exp)."""
        exp_multiplier = 0
        base_exp = self.question.exp_points
        final_exp = int(base_exp * exp_multiplier)
        
        self.assertEqual(final_exp, 0)
        self.assertEqual(exp_multiplier, 0)
