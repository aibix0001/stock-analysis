#!/usr/bin/env python3
"""
Build verification tests for LXC template
"""
import unittest
import os
import tarfile
import tempfile
import shutil
import json
import yaml
from pathlib import Path


class TestBuildVerification(unittest.TestCase):
    """Verify the built template meets all requirements"""
    
    @classmethod
    def setUpClass(cls):
        """Set up test environment once for all tests"""
        cls.build_dir = Path(__file__).parent.parent
        cls.output_dir = cls.build_dir / "output"
        cls.template_path = cls.output_dir / "stock-analysis-lxc-template-latest.tar.gz"
        
        # Extract template for testing
        cls.test_dir = tempfile.mkdtemp()
        cls.extract_dir = Path(cls.test_dir) / "extracted"
        cls.extract_dir.mkdir()
        
        if cls.template_path.exists():
            with tarfile.open(cls.template_path, 'r:gz') as tar:
                tar.extractall(cls.extract_dir)
    
    @classmethod
    def tearDownClass(cls):
        """Clean up test environment"""
        shutil.rmtree(cls.test_dir)
    
    def test_template_exists(self):
        """Test that template file was created"""
        self.assertTrue(self.template_path.exists(), 
                       "Template file should exist")
        self.assertGreater(self.template_path.stat().st_size, 1000,
                          "Template file should not be empty")
    
    def test_template_structure(self):
        """Test that template has correct structure"""
        required_items = [
            "rootfs",
            "metadata.yaml",
            "templates/hostname.tpl",
            "templates/hosts.tpl",
            "templates/interfaces.tpl"
        ]
        
        for item in required_items:
            item_path = self.extract_dir / item
            self.assertTrue(item_path.exists(),
                          f"Template should contain {item}")
    
    def test_metadata_content(self):
        """Test metadata.yaml has correct content"""
        metadata_path = self.extract_dir / "metadata.yaml"
        self.assertTrue(metadata_path.exists())
        
        with open(metadata_path, 'r') as f:
            metadata = yaml.safe_load(f)
        
        # Check required fields
        self.assertEqual(metadata['architecture'], 'x86_64')
        self.assertEqual(metadata['properties']['os'], 'debian')
        self.assertEqual(metadata['properties']['release'], 'bookworm')
        self.assertEqual(metadata['properties']['version'], '12')
        self.assertIn('Stock Analysis', metadata['properties']['description'])
    
    def test_installation_scripts(self):
        """Test all installation scripts are present"""
        scripts = [
            "setup-system.sh",
            "setup-python.sh",
            "setup-databases.sh",
            "setup-services.sh",
            "health-check.py"
        ]
        
        scripts_dir = self.extract_dir / "rootfs/opt/stock-analysis/scripts"
        self.assertTrue(scripts_dir.exists())
        
        for script in scripts:
            script_path = scripts_dir / script
            self.assertTrue(script_path.exists(),
                          f"Script {script} should exist")
            # Check executable permission
            self.assertTrue(os.access(script_path, os.X_OK),
                          f"Script {script} should be executable")
    
    def test_systemd_services(self):
        """Test systemd service files are present"""
        services = [
            "stock-analysis-broker-gateway.service",
            "stock-analysis-intelligent-core.service",
            "stock-analysis-event-bus.service",
            "stock-analysis-monitoring.service",
            "stock-analysis-frontend.service"
        ]
        
        systemd_dir = self.extract_dir / "rootfs/opt/stock-analysis/config/systemd"
        self.assertTrue(systemd_dir.exists())
        
        for service in services:
            service_path = systemd_dir / service
            self.assertTrue(service_path.exists(),
                          f"Service {service} should exist")
            
            # Verify service content
            content = service_path.read_text()
            self.assertIn("[Unit]", content)
            self.assertIn("[Service]", content)
            self.assertIn("[Install]", content)
            self.assertIn("Type=simple", content)
            self.assertIn("Restart=always", content)
    
    def test_configuration_files(self):
        """Test configuration files are present"""
        config_files = {
            "postgresql/init.sql": ["CREATE SCHEMA", "event_store"],
            "redis/setup-cluster.sh": ["redis-cli", "--cluster create"],
            "rabbitmq/definitions.json": ["vhosts", "exchanges", "queues"]
        }
        
        config_dir = self.extract_dir / "rootfs/opt/stock-analysis/config"
        
        for file_path, required_content in config_files.items():
            full_path = config_dir / file_path
            self.assertTrue(full_path.exists(),
                          f"Config file {file_path} should exist")
            
            content = full_path.read_text()
            for text in required_content:
                self.assertIn(text, content,
                            f"Config {file_path} should contain '{text}'")
    
    def test_first_boot_setup(self):
        """Test first boot configuration"""
        first_boot_script = self.extract_dir / "rootfs/opt/stock-analysis/first-boot.sh"
        self.assertTrue(first_boot_script.exists())
        self.assertTrue(os.access(first_boot_script, os.X_OK))
        
        # Check content
        content = first_boot_script.read_text()
        self.assertIn("setup-system.sh", content)
        self.assertIn("setup-python.sh", content)
        self.assertIn("setup-databases.sh", content)
        self.assertIn("setup-services.sh", content)
        
        # Check systemd service
        service_path = self.extract_dir / "rootfs/etc/systemd/system/stock-analysis-first-boot.service"
        self.assertTrue(service_path.exists())
        
        # Check service is enabled
        wants_link = self.extract_dir / "rootfs/etc/systemd/system/multi-user.target.wants/stock-analysis-first-boot.service"
        self.assertTrue(wants_link.exists() or wants_link.is_symlink())
    
    def test_directory_structure(self):
        """Test required directories are created"""
        required_dirs = [
            "rootfs/etc/systemd/system",
            "rootfs/opt/stock-analysis/scripts",
            "rootfs/opt/stock-analysis/config",
            "rootfs/opt/stock-analysis/venvs",
            "rootfs/var/lib/postgresql",
            "rootfs/var/lib/redis",
            "rootfs/var/lib/rabbitmq",
            "rootfs/etc/stock-analysis"
        ]
        
        for dir_path in required_dirs:
            full_path = self.extract_dir / dir_path
            self.assertTrue(full_path.exists() and full_path.is_dir(),
                          f"Directory {dir_path} should exist")
    
    def test_network_configuration(self):
        """Test network configuration templates"""
        interfaces_tpl = self.extract_dir / "templates/interfaces.tpl"
        self.assertTrue(interfaces_tpl.exists())
        
        content = interfaces_tpl.read_text()
        self.assertIn("auto eth0", content)
        self.assertIn("iface eth0 inet dhcp", content)
    
    def test_health_check_script(self):
        """Test health check script functionality"""
        health_check = self.extract_dir / "rootfs/opt/stock-analysis/scripts/health-check.py"
        self.assertTrue(health_check.exists())
        
        content = health_check.read_text()
        self.assertIn("def check_postgresql", content)
        self.assertIn("def check_redis", content)
        self.assertIn("def check_rabbitmq", content)
        self.assertIn("def check_service_status", content)
    
    def test_documentation(self):
        """Test that documentation was generated"""
        readme_path = self.output_dir / "README.md"
        self.assertTrue(readme_path.exists())
        
        content = readme_path.read_text()
        self.assertIn("Stock Analysis LXC Template", content)
        self.assertIn("Deployment Instructions", content)
        self.assertIn("pct create", content)
        self.assertIn("Service Ports", content)
        self.assertIn("Default Credentials", content)
    
    def test_checksum_file(self):
        """Test that checksum file was created"""
        checksum_files = list(self.output_dir.glob("*.sha256"))
        self.assertGreater(len(checksum_files), 0,
                          "At least one checksum file should exist")
        
        # Verify checksum format
        for checksum_file in checksum_files:
            content = checksum_file.read_text()
            # SHA256 checksum should be 64 characters
            parts = content.strip().split()
            self.assertEqual(len(parts[0]), 64,
                           "SHA256 checksum should be 64 characters")


class TestScriptContent(unittest.TestCase):
    """Test the content of generated scripts"""
    
    @classmethod
    def setUpClass(cls):
        """Set up for script content tests"""
        cls.build_dir = Path(__file__).parent.parent
        cls.scripts_dir = cls.build_dir / "scripts"
    
    def test_setup_system_packages(self):
        """Test system setup script includes all required packages"""
        script_path = self.scripts_dir / "setup-system.sh"
        if script_path.exists():
            content = script_path.read_text()
            
            required_packages = [
                "python3",
                "python3-pip",
                "python3-venv",
                "postgresql-client",
                "redis-tools",
                "systemd",
                "libpq-dev"
            ]
            
            for package in required_packages:
                self.assertIn(package, content,
                            f"Package {package} should be in setup-system.sh")
    
    def test_python_setup_venvs(self):
        """Test Python setup creates all service venvs"""
        script_path = self.scripts_dir / "setup-python.sh"
        if script_path.exists():
            content = script_path.read_text()
            
            services = [
                "broker-gateway",
                "intelligent-core",
                "event-bus",
                "monitoring",
                "frontend"
            ]
            
            for service in services:
                self.assertIn(service, content,
                            f"Service {service} should be mentioned in setup script")
    
    def test_database_credentials(self):
        """Test database setup uses consistent credentials"""
        script_path = self.scripts_dir / "setup-databases.sh"
        if script_path.exists():
            content = script_path.read_text()
            
            # Check PostgreSQL setup
            self.assertIn("stock_analysis_user", content)
            self.assertIn("stock_analysis_event_store", content)
            
            # Check Redis setup
            self.assertIn("requirepass changeme", content)
            
            # Check RabbitMQ setup
            self.assertIn("stock_analysis", content)
            self.assertIn("/stock-analysis", content)


if __name__ == '__main__':
    unittest.main()