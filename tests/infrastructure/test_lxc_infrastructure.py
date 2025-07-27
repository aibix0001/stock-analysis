#!/usr/bin/env python3
"""
Comprehensive test suite for LXC infrastructure setup
Tests system configuration, services, and environment readiness
"""

import os
import sys
import subprocess
import socket
import json
import psutil
import platform
from pathlib import Path
from typing import Dict, List, Tuple, Optional

# ANSI color codes
GREEN = '\033[92m'
RED = '\033[91m'
YELLOW = '\033[93m'
BLUE = '\033[94m'
RESET = '\033[0m'

class InfrastructureTest:
    """Test suite for stock-analysis LXC infrastructure"""
    
    def __init__(self):
        self.test_results = []
        self.passed = 0
        self.failed = 0
        self.warnings = 0
        
        # Expected configuration
        self.expected_config = {
            'debian_version': '12',
            'python_min_version': (3, 11),
            'node_min_version': 18,
            'postgresql_version': 15,
            'container_ip': '10.1.1.120',
            'container_hostname': 'stock-analysis',
            'base_dir': '/opt/stock-analysis',
            'service_user': 'stock-analysis'
        }
    
    def log_test(self, test_name: str):
        """Log test execution"""
        print(f"{BLUE}[TEST]{RESET} {test_name}")
    
    def log_pass(self, message: str):
        """Log passed test"""
        print(f"{GREEN}[PASS]{RESET} {message}")
        self.passed += 1
        self.test_results.append(('PASS', message))
    
    def log_fail(self, message: str):
        """Log failed test"""
        print(f"{RED}[FAIL]{RESET} {message}")
        self.failed += 1
        self.test_results.append(('FAIL', message))
    
    def log_warning(self, message: str):
        """Log warning"""
        print(f"{YELLOW}[WARN]{RESET} {message}")
        self.warnings += 1
        self.test_results.append(('WARN', message))
    
    def run_command(self, command: List[str]) -> Tuple[int, str, str]:
        """Run shell command and return result"""
        try:
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                check=False
            )
            return result.returncode, result.stdout, result.stderr
        except Exception as e:
            return -1, '', str(e)
    
    def test_system_info(self):
        """Test system information and OS version"""
        self.log_test("System Information")
        
        # Check OS release
        try:
            with open('/etc/os-release', 'r') as f:
                os_info = dict(line.strip().split('=', 1) for line in f if '=' in line)
                os_info = {k: v.strip('"') for k, v in os_info.items()}
                
            if 'VERSION_ID' in os_info:
                if os_info['VERSION_ID'] == self.expected_config['debian_version']:
                    self.log_pass(f"Debian {os_info['VERSION_ID']} detected")
                else:
                    self.log_fail(f"Expected Debian {self.expected_config['debian_version']}, found {os_info['VERSION_ID']}")
            else:
                self.log_fail("Could not determine Debian version")
                
        except Exception as e:
            self.log_fail(f"Failed to read OS information: {e}")
        
        # Check kernel and architecture
        kernel = platform.release()
        arch = platform.machine()
        self.log_pass(f"Kernel: {kernel}, Architecture: {arch}")
    
    def test_network_configuration(self):
        """Test network configuration"""
        self.log_test("Network Configuration")
        
        # Check hostname
        hostname = socket.gethostname()
        if hostname == self.expected_config['container_hostname']:
            self.log_pass(f"Hostname correctly set to {hostname}")
        else:
            self.log_fail(f"Expected hostname {self.expected_config['container_hostname']}, found {hostname}")
        
        # Check IP configuration
        try:
            # Get all network interfaces
            import netifaces
            
            for interface in netifaces.interfaces():
                if interface == 'lo':
                    continue
                    
                addrs = netifaces.ifaddresses(interface)
                if netifaces.AF_INET in addrs:
                    for addr in addrs[netifaces.AF_INET]:
                        if addr['addr'] == self.expected_config['container_ip']:
                            self.log_pass(f"IP address {addr['addr']} found on {interface}")
                            return
            
            self.log_fail(f"Expected IP {self.expected_config['container_ip']} not found")
            
        except ImportError:
            # Fallback to ip command
            code, stdout, _ = self.run_command(['ip', 'addr', 'show'])
            if code == 0 and self.expected_config['container_ip'] in stdout:
                self.log_pass(f"IP address {self.expected_config['container_ip']} configured")
            else:
                self.log_fail(f"IP address {self.expected_config['container_ip']} not found")
    
    def test_python_environment(self):
        """Test Python installation and version"""
        self.log_test("Python Environment")
        
        # Check Python version
        python_version = sys.version_info
        min_version = self.expected_config['python_min_version']
        
        if python_version >= min_version:
            self.log_pass(f"Python {python_version.major}.{python_version.minor}.{python_version.micro} meets requirements")
        else:
            self.log_fail(f"Python {python_version.major}.{python_version.minor} does not meet minimum {min_version}")
        
        # Check pip
        code, stdout, _ = self.run_command(['python3', '-m', 'pip', '--version'])
        if code == 0:
            self.log_pass("pip is available")
        else:
            self.log_fail("pip is not available")
        
        # Check venv module
        code, _, _ = self.run_command(['python3', '-c', 'import venv'])
        if code == 0:
            self.log_pass("venv module is available")
        else:
            self.log_fail("venv module is not available")
        
        # Check uv
        code, stdout, _ = self.run_command(['uv', '--version'])
        if code == 0:
            self.log_pass(f"uv package manager installed: {stdout.strip()}")
        else:
            self.log_fail("uv package manager not installed")
    
    def test_nodejs_environment(self):
        """Test Node.js installation"""
        self.log_test("Node.js Environment")
        
        # Check Node.js version
        code, stdout, _ = self.run_command(['node', '--version'])
        if code == 0:
            version = stdout.strip()
            try:
                major_version = int(version.split('.')[0].replace('v', ''))
                if major_version >= self.expected_config['node_min_version']:
                    self.log_pass(f"Node.js {version} meets requirements")
                else:
                    self.log_fail(f"Node.js {version} does not meet minimum v{self.expected_config['node_min_version']}")
            except:
                self.log_fail(f"Could not parse Node.js version: {version}")
        else:
            self.log_fail("Node.js is not installed")
        
        # Check npm
        code, stdout, _ = self.run_command(['npm', '--version'])
        if code == 0:
            self.log_pass(f"npm {stdout.strip()} is available")
        else:
            self.log_fail("npm is not available")
    
    def test_database_services(self):
        """Test database service installations"""
        self.log_test("Database Services")
        
        # Test PostgreSQL
        code, stdout, _ = self.run_command(['psql', '--version'])
        if code == 0:
            if f"psql (PostgreSQL) {self.expected_config['postgresql_version']}" in stdout:
                self.log_pass(f"PostgreSQL {self.expected_config['postgresql_version']} installed")
            else:
                self.log_warning(f"PostgreSQL installed but version mismatch: {stdout.strip()}")
        else:
            self.log_fail("PostgreSQL is not installed")
        
        # Check PostgreSQL service
        code, _, _ = self.run_command(['systemctl', 'is-active', 'postgresql'])
        if code == 0:
            self.log_pass("PostgreSQL service is running")
        else:
            self.log_fail("PostgreSQL service is not running")
        
        # Test Redis
        code, stdout, _ = self.run_command(['redis-server', '--version'])
        if code == 0:
            self.log_pass(f"Redis installed: {stdout.strip()}")
        else:
            self.log_fail("Redis is not installed")
        
        # Check Redis service
        code, _, _ = self.run_command(['systemctl', 'is-active', 'redis-server'])
        if code == 0:
            self.log_pass("Redis service is running")
        else:
            self.log_fail("Redis service is not running")
        
        # Test RabbitMQ
        code, _, _ = self.run_command(['rabbitmqctl', 'version'])
        if code == 0:
            self.log_pass("RabbitMQ is installed")
        else:
            self.log_fail("RabbitMQ is not installed")
        
        # Check RabbitMQ service
        code, _, _ = self.run_command(['systemctl', 'is-active', 'rabbitmq-server'])
        if code == 0:
            self.log_pass("RabbitMQ service is running")
        else:
            self.log_fail("RabbitMQ service is not running")
    
    def test_directory_structure(self):
        """Test directory structure and permissions"""
        self.log_test("Directory Structure")
        
        base_dir = Path(self.expected_config['base_dir'])
        
        # Required directories
        required_dirs = [
            base_dir,
            base_dir / 'venvs',
            base_dir / 'scripts',
            base_dir / 'config',
            base_dir / 'logs',
            base_dir / 'data',
            base_dir / 'services',
            Path('/etc/stock-analysis'),
            Path('/var/log/stock-analysis')
        ]
        
        for directory in required_dirs:
            if directory.exists() and directory.is_dir():
                self.log_pass(f"Directory {directory} exists")
                
                # Check if writable by service user
                if os.access(directory, os.W_OK):
                    self.log_pass(f"Directory {directory} is writable")
                else:
                    self.log_warning(f"Directory {directory} may not be writable by current user")
            else:
                self.log_fail(f"Directory {directory} does not exist")
    
    def test_service_user(self):
        """Test service user configuration"""
        self.log_test("Service User Configuration")
        
        # Check if user exists
        code, stdout, _ = self.run_command(['id', self.expected_config['service_user']])
        if code == 0:
            self.log_pass(f"User '{self.expected_config['service_user']}' exists")
            
            # Parse user info
            if 'groups=' in stdout:
                groups = stdout.split('groups=')[1].strip()
                if 'redis' in groups:
                    self.log_pass("User is in redis group")
                else:
                    self.log_warning("User is not in redis group")
                
                if 'postgres' in groups:
                    self.log_pass("User is in postgres group")
                else:
                    self.log_warning("User is not in postgres group")
        else:
            self.log_fail(f"User '{self.expected_config['service_user']}' does not exist")
    
    def test_systemd_configuration(self):
        """Test systemd configuration"""
        self.log_test("Systemd Configuration")
        
        # Check systemd availability
        code, stdout, _ = self.run_command(['systemctl', '--version'])
        if code == 0:
            version = stdout.split('\n')[0]
            self.log_pass(f"systemd available: {version}")
        else:
            self.log_fail("systemd is not available")
        
        # Check system state
        code, stdout, _ = self.run_command(['systemctl', 'is-system-running'])
        if code == 0 or stdout.strip() in ['running', 'degraded']:
            self.log_pass(f"systemd is {stdout.strip()}")
        else:
            self.log_fail(f"systemd state: {stdout.strip()}")
        
        # Check for template files
        template_files = [
            '/etc/stock-analysis/python-service.template',
            '/etc/stock-analysis/health-check.template',
            '/etc/stock-analysis/environment'
        ]
        
        for template in template_files:
            if Path(template).exists():
                self.log_pass(f"Template file {template} exists")
            else:
                self.log_fail(f"Template file {template} missing")
    
    def test_environment_readiness(self):
        """Test overall environment readiness"""
        self.log_test("Environment Readiness")
        
        # Check setup completion marker
        marker_file = Path(self.expected_config['base_dir']) / '.setup-complete'
        if marker_file.exists():
            self.log_pass("Setup completion marker found")
            
            # Read and validate marker content
            try:
                with open(marker_file, 'r') as f:
                    content = f.read()
                    if 'SETUP_DATE' in content:
                        self.log_pass("Setup marker contains metadata")
            except:
                self.log_warning("Could not read setup marker content")
        else:
            self.log_fail("Setup completion marker not found")
        
        # Check environment file
        env_file = Path('/etc/stock-analysis/environment')
        if env_file.exists():
            self.log_pass("Environment configuration file exists")
            
            # Validate key environment variables
            try:
                with open(env_file, 'r') as f:
                    env_content = f.read()
                    required_vars = [
                        'STOCK_ANALYSIS_HOME',
                        'POSTGRES_HOST',
                        'REDIS_HOST',
                        'RABBITMQ_HOST'
                    ]
                    
                    for var in required_vars:
                        if var in env_content:
                            self.log_pass(f"Environment variable {var} is defined")
                        else:
                            self.log_fail(f"Environment variable {var} is missing")
            except:
                self.log_warning("Could not validate environment file content")
        else:
            self.log_fail("Environment configuration file missing")
    
    def generate_report(self):
        """Generate test report"""
        print("\n" + "="*50)
        print("Infrastructure Test Report")
        print("="*50)
        
        total_tests = self.passed + self.failed
        
        print(f"\nTotal Tests: {total_tests}")
        print(f"{GREEN}Passed: {self.passed}{RESET}")
        print(f"{RED}Failed: {self.failed}{RESET}")
        print(f"{YELLOW}Warnings: {self.warnings}{RESET}")
        
        if self.failed == 0:
            print(f"\n{GREEN}✅ All infrastructure tests passed!{RESET}")
            return 0
        else:
            print(f"\n{RED}❌ Some infrastructure tests failed!{RESET}")
            
            # Show failed tests
            print("\nFailed Tests:")
            for status, message in self.test_results:
                if status == 'FAIL':
                    print(f"  - {message}")
            
            return 1
    
    def run_all_tests(self):
        """Run all infrastructure tests"""
        print("Stock Analysis LXC Infrastructure Tests")
        print("="*50)
        print()
        
        # Run test suites
        self.test_system_info()
        self.test_network_configuration()
        self.test_python_environment()
        self.test_nodejs_environment()
        self.test_database_services()
        self.test_directory_structure()
        self.test_service_user()
        self.test_systemd_configuration()
        self.test_environment_readiness()
        
        # Generate report
        return self.generate_report()


if __name__ == '__main__':
    # Check if running as root (some tests may require it)
    if os.geteuid() != 0:
        print(f"{YELLOW}Warning: Some tests may require root privileges{RESET}")
    
    # Run tests
    tester = InfrastructureTest()
    exit_code = tester.run_all_tests()
    sys.exit(exit_code)