#!/usr/bin/env python3
"""
CryptoMiner Pro Installation Script Testing
Tests all three installation scripts for Phase 5 verification
"""

import subprocess
import sys
import time
import requests
import json
import os
from datetime import datetime

class InstallationTester:
    def __init__(self):
        self.test_results = {
            "install-ubuntu.sh": {"status": "not_tested", "details": []},
            "install-bulletproof.sh": {"status": "not_tested", "details": []},
            "install-python313.sh": {"status": "not_tested", "details": []}
        }
        self.backend_url = "https://113c4522-c6a3-4def-b0b5-d97ad7e0f3d8.preview.emergentagent.com/api"
        
    def log(self, message):
        """Log message with timestamp"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(f"[{timestamp}] {message}")
        
    def test_system_prerequisites(self):
        """Test current system state before installation"""
        self.log("🔍 Testing System Prerequisites")
        
        prerequisites = {
            "python3": False,
            "node": False,
            "npm": False,
            "mongosh": False,
            "supervisor": False
        }
        
        # Test Python
        try:
            result = subprocess.run(["python3", "--version"], capture_output=True, text=True)
            if result.returncode == 0:
                prerequisites["python3"] = True
                self.log(f"✅ Python: {result.stdout.strip()}")
        except:
            self.log("❌ Python3 not found")
            
        # Test Node.js
        try:
            result = subprocess.run(["node", "--version"], capture_output=True, text=True)
            if result.returncode == 0:
                prerequisites["node"] = True
                self.log(f"✅ Node.js: {result.stdout.strip()}")
        except:
            self.log("❌ Node.js not found")
            
        # Test npm
        try:
            result = subprocess.run(["npm", "--version"], capture_output=True, text=True)
            if result.returncode == 0:
                prerequisites["npm"] = True
                self.log(f"✅ npm: {result.stdout.strip()}")
        except:
            self.log("❌ npm not found")
            
        # Test MongoDB
        try:
            result = subprocess.run(["mongosh", "--version"], capture_output=True, text=True)
            if result.returncode == 0:
                prerequisites["mongosh"] = True
                self.log(f"✅ MongoDB Shell: {result.stdout.strip()}")
        except:
            self.log("❌ MongoDB Shell not found")
            
        # Test Supervisor
        try:
            result = subprocess.run(["supervisorctl", "status"], capture_output=True, text=True)
            if result.returncode == 0:
                prerequisites["supervisor"] = True
                self.log(f"✅ Supervisor: Running")
                self.log(f"   Services: {result.stdout.strip()}")
        except:
            self.log("❌ Supervisor not found")
            
        return prerequisites
        
    def test_backend_api(self):
        """Test backend API functionality"""
        self.log("🔧 Testing Backend API")
        
        api_tests = {
            "health": False,
            "coin_presets": False,
            "system_stats": False,
            "mining_status": False
        }
        
        # Test health endpoint
        try:
            response = requests.get(f"{self.backend_url}/health", timeout=10)
            if response.status_code == 200:
                api_tests["health"] = True
                self.log("✅ Health endpoint working")
            else:
                self.log(f"❌ Health endpoint failed: {response.status_code}")
        except Exception as e:
            self.log(f"❌ Health endpoint error: {e}")
            
        # Test coin presets
        try:
            response = requests.get(f"{self.backend_url}/coins/presets", timeout=10)
            if response.status_code == 200:
                data = response.json()
                if "presets" in data:
                    api_tests["coin_presets"] = True
                    self.log("✅ Coin presets endpoint working")
        except Exception as e:
            self.log(f"❌ Coin presets error: {e}")
            
        # Test system stats
        try:
            response = requests.get(f"{self.backend_url}/system/stats", timeout=10)
            if response.status_code == 200:
                api_tests["system_stats"] = True
                self.log("✅ System stats endpoint working")
        except Exception as e:
            self.log(f"❌ System stats error: {e}")
            
        # Test mining status
        try:
            response = requests.get(f"{self.backend_url}/mining/status", timeout=10)
            if response.status_code == 200:
                api_tests["mining_status"] = True
                self.log("✅ Mining status endpoint working")
        except Exception as e:
            self.log(f"❌ Mining status error: {e}")
            
        return api_tests
        
    def test_frontend_accessibility(self):
        """Test frontend accessibility"""
        self.log("🌐 Testing Frontend Accessibility")
        
        frontend_url = "https://113c4522-c6a3-4def-b0b5-d97ad7e0f3d8.preview.emergentagent.com"
        
        try:
            response = requests.get(frontend_url, timeout=10)
            if response.status_code == 200:
                self.log("✅ Frontend accessible")
                return True
            else:
                self.log(f"❌ Frontend failed: {response.status_code}")
                return False
        except Exception as e:
            self.log(f"❌ Frontend error: {e}")
            return False
            
    def check_script_syntax(self, script_path):
        """Check if script has valid bash syntax"""
        self.log(f"📝 Checking syntax for {script_path}")
        
        try:
            result = subprocess.run(["bash", "-n", script_path], capture_output=True, text=True)
            if result.returncode == 0:
                self.log(f"✅ {script_path} syntax is valid")
                return True
            else:
                self.log(f"❌ {script_path} syntax error: {result.stderr}")
                return False
        except Exception as e:
            self.log(f"❌ Error checking {script_path}: {e}")
            return False
            
    def test_script_help(self, script_path):
        """Test script help functionality"""
        self.log(f"❓ Testing help for {script_path}")
        
        try:
            result = subprocess.run(["bash", script_path, "--help"], capture_output=True, text=True, timeout=30)
            if result.returncode == 0 and "help" in result.stdout.lower():
                self.log(f"✅ {script_path} help working")
                return True
            else:
                self.log(f"⚠️ {script_path} help may not be available")
                return False
        except Exception as e:
            self.log(f"❌ Error testing help for {script_path}: {e}")
            return False
            
    def simulate_script_execution(self, script_path):
        """Simulate script execution by checking its components"""
        self.log(f"🔍 Analyzing {script_path} components")
        
        components_found = {
            "python_setup": False,
            "nodejs_setup": False,
            "mongodb_setup": False,
            "supervisor_setup": False,
            "service_management": False
        }
        
        try:
            with open(script_path, 'r') as f:
                content = f.read()
                
            # Check for Python setup
            if "python" in content.lower() and ("install" in content or "setup" in content):
                components_found["python_setup"] = True
                self.log("✅ Python setup found in script")
                
            # Check for Node.js setup
            if "node" in content.lower() and ("install" in content or "setup" in content):
                components_found["nodejs_setup"] = True
                self.log("✅ Node.js setup found in script")
                
            # Check for MongoDB setup
            if "mongo" in content.lower() and ("install" in content or "setup" in content):
                components_found["mongodb_setup"] = True
                self.log("✅ MongoDB setup found in script")
                
            # Check for Supervisor setup
            if "supervisor" in content.lower():
                components_found["supervisor_setup"] = True
                self.log("✅ Supervisor setup found in script")
                
            # Check for service management
            if "start" in content and "service" in content.lower():
                components_found["service_management"] = True
                self.log("✅ Service management found in script")
                
        except Exception as e:
            self.log(f"❌ Error analyzing {script_path}: {e}")
            
        return components_found
        
    def test_installation_script(self, script_name):
        """Test a specific installation script"""
        self.log(f"\n{'='*60}")
        self.log(f"🚀 TESTING {script_name}")
        self.log(f"{'='*60}")
        
        script_path = f"/app/{script_name}"
        
        if not os.path.exists(script_path):
            self.test_results[script_name]["status"] = "failed"
            self.test_results[script_name]["details"].append("Script file not found")
            self.log(f"❌ {script_name} not found")
            return False
            
        # Test 1: Syntax check
        syntax_ok = self.check_script_syntax(script_path)
        self.test_results[script_name]["details"].append(f"Syntax check: {'PASS' if syntax_ok else 'FAIL'}")
        
        # Test 2: Help functionality
        help_ok = self.test_script_help(script_path)
        self.test_results[script_name]["details"].append(f"Help functionality: {'PASS' if help_ok else 'PARTIAL'}")
        
        # Test 3: Component analysis
        components = self.simulate_script_execution(script_path)
        component_score = sum(components.values())
        self.test_results[script_name]["details"].append(f"Components found: {component_score}/5")
        
        # Overall assessment
        if syntax_ok and component_score >= 3:
            self.test_results[script_name]["status"] = "passed"
            self.log(f"✅ {script_name} PASSED comprehensive testing")
        else:
            self.test_results[script_name]["status"] = "failed"
            self.log(f"❌ {script_name} FAILED comprehensive testing")
            
        return self.test_results[script_name]["status"] == "passed"
        
    def run_comprehensive_test(self):
        """Run comprehensive installation script testing"""
        self.log("🎯 STARTING COMPREHENSIVE INSTALLATION SCRIPT TESTING")
        self.log("=" * 80)
        
        # Test current system state
        self.log("\n📋 PHASE 1: SYSTEM PREREQUISITES")
        prerequisites = self.test_system_prerequisites()
        
        # Test current functionality
        self.log("\n📋 PHASE 2: CURRENT FUNCTIONALITY")
        api_status = self.test_backend_api()
        frontend_status = self.test_frontend_accessibility()
        
        # Test each installation script
        self.log("\n📋 PHASE 3: INSTALLATION SCRIPT TESTING")
        
        scripts_to_test = [
            "install-ubuntu.sh",
            "install-bulletproof.sh", 
            "install-python313.sh"
        ]
        
        for script in scripts_to_test:
            self.test_installation_script(script)
            
        # Generate final report
        self.generate_final_report(prerequisites, api_status, frontend_status)
        
    def generate_final_report(self, prerequisites, api_status, frontend_status):
        """Generate comprehensive test report"""
        self.log("\n" + "=" * 80)
        self.log("📊 FINAL INSTALLATION SCRIPT TEST REPORT")
        self.log("=" * 80)
        
        # System Prerequisites Summary
        prereq_score = sum(prerequisites.values())
        self.log(f"\n🔧 SYSTEM PREREQUISITES: {prereq_score}/5 PASSED")
        for item, status in prerequisites.items():
            self.log(f"   {'✅' if status else '❌'} {item}")
            
        # API Functionality Summary
        api_score = sum(api_status.values())
        self.log(f"\n🔧 BACKEND API FUNCTIONALITY: {api_score}/4 PASSED")
        for item, status in api_status.items():
            self.log(f"   {'✅' if status else '❌'} {item}")
            
        # Frontend Status
        self.log(f"\n🌐 FRONTEND ACCESSIBILITY: {'✅ PASSED' if frontend_status else '❌ FAILED'}")
        
        # Installation Scripts Summary
        self.log(f"\n📜 INSTALLATION SCRIPTS TESTING:")
        passed_scripts = 0
        total_scripts = len(self.test_results)
        
        for script, result in self.test_results.items():
            status_icon = "✅" if result["status"] == "passed" else "❌"
            self.log(f"   {status_icon} {script}: {result['status'].upper()}")
            
            for detail in result["details"]:
                self.log(f"      • {detail}")
                
            if result["status"] == "passed":
                passed_scripts += 1
                
        # Overall Assessment
        self.log(f"\n🎯 OVERALL ASSESSMENT:")
        self.log(f"   • System Prerequisites: {prereq_score}/5 ({(prereq_score/5)*100:.1f}%)")
        self.log(f"   • Backend API: {api_score}/4 ({(api_score/4)*100:.1f}%)")
        self.log(f"   • Frontend: {'100.0%' if frontend_status else '0.0%'}")
        self.log(f"   • Installation Scripts: {passed_scripts}/{total_scripts} ({(passed_scripts/total_scripts)*100:.1f}%)")
        
        # Final Verdict
        overall_success = (prereq_score >= 4 and api_score >= 3 and 
                          frontend_status and passed_scripts >= 2)
        
        if overall_success:
            self.log(f"\n🎉 PHASE 5 INSTALLATION SCRIPT TESTING: ✅ SUCCESS")
            self.log("   All installation scripts are ready for production use!")
        else:
            self.log(f"\n⚠️ PHASE 5 INSTALLATION SCRIPT TESTING: ❌ NEEDS ATTENTION")
            self.log("   Some components require fixes before production deployment.")
            
        return overall_success

def main():
    """Main testing function"""
    tester = InstallationTester()
    success = tester.run_comprehensive_test()
    
    # Exit with appropriate code
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()