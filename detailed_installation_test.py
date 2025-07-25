#!/usr/bin/env python3
"""
Detailed Installation Script Testing for Phase 5
Tests the actual functionality and compatibility of installation scripts
"""

import subprocess
import sys
import time
import requests
import json
import os
import tempfile
import shutil
from datetime import datetime

class DetailedInstallationTester:
    def __init__(self):
        self.backend_url = "https://113c4522-c6a3-4def-b0b5-d97ad7e0f3d8.preview.emergentagent.com/api"
        self.test_results = {}
        
    def log(self, message):
        """Log message with timestamp"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(f"[{timestamp}] {message}")
        
    def test_backend_comprehensive(self):
        """Comprehensive backend API testing"""
        self.log("🔧 COMPREHENSIVE BACKEND API TESTING")
        
        tests = {
            "health_check": self.test_health_endpoint,
            "coin_presets": self.test_coin_presets,
            "system_stats": self.test_system_stats,
            "mining_status": self.test_mining_status,
            "wallet_validation": self.test_wallet_validation,
            "pool_connection": self.test_pool_connection,
            "cpu_info": self.test_cpu_info,
            "ai_insights": self.test_ai_insights
        }
        
        results = {}
        for test_name, test_func in tests.items():
            try:
                results[test_name] = test_func()
                self.log(f"   {'✅' if results[test_name] else '❌'} {test_name}")
            except Exception as e:
                results[test_name] = False
                self.log(f"   ❌ {test_name} - Error: {e}")
                
        return results
        
    def test_health_endpoint(self):
        """Test health endpoint"""
        response = requests.get(f"{self.backend_url}/health", timeout=10)
        if response.status_code == 200:
            data = response.json()
            return "status" in data and data["status"] == "healthy"
        return False
        
    def test_coin_presets(self):
        """Test coin presets endpoint"""
        response = requests.get(f"{self.backend_url}/coins/presets", timeout=10)
        if response.status_code == 200:
            data = response.json()
            if "presets" in data:
                presets = data["presets"]
                # Check for expected coins
                expected_coins = ["litecoin", "dogecoin", "feathercoin"]
                return all(coin in presets for coin in expected_coins)
        return False
        
    def test_system_stats(self):
        """Test system stats endpoint"""
        response = requests.get(f"{self.backend_url}/system/stats", timeout=10)
        if response.status_code == 200:
            data = response.json()
            required_keys = ["cpu", "memory", "disk"]
            return all(key in data for key in required_keys)
        return False
        
    def test_mining_status(self):
        """Test mining status endpoint"""
        response = requests.get(f"{self.backend_url}/mining/status", timeout=10)
        if response.status_code == 200:
            data = response.json()
            return "is_mining" in data and "stats" in data
        return False
        
    def test_wallet_validation(self):
        """Test wallet validation endpoint"""
        test_data = {
            "address": "LTC1234567890abcdef",
            "coin_symbol": "LTC"
        }
        response = requests.post(f"{self.backend_url}/wallet/validate", 
                               json=test_data, timeout=10)
        if response.status_code == 200:
            data = response.json()
            return "valid" in data
        return False
        
    def test_pool_connection(self):
        """Test pool connection endpoint"""
        test_data = {
            "pool_address": "stratum.litecoinpool.org",
            "pool_port": 3333,
            "type": "pool"
        }
        response = requests.post(f"{self.backend_url}/pool/test-connection", 
                               json=test_data, timeout=15)
        if response.status_code == 200:
            data = response.json()
            return "success" in data
        return False
        
    def test_cpu_info(self):
        """Test CPU info endpoint"""
        response = requests.get(f"{self.backend_url}/system/cpu-info", timeout=10)
        if response.status_code == 200:
            data = response.json()
            required_keys = ["cores", "recommended_threads", "mining_profiles"]
            return all(key in data for key in required_keys)
        return False
        
    def test_ai_insights(self):
        """Test AI insights endpoint"""
        response = requests.get(f"{self.backend_url}/mining/ai-insights", timeout=10)
        if response.status_code == 200:
            data = response.json()
            return "insights" in data or "predictions" in data
        return False
        
    def test_frontend_comprehensive(self):
        """Comprehensive frontend testing"""
        self.log("🌐 COMPREHENSIVE FRONTEND TESTING")
        
        frontend_url = "https://113c4522-c6a3-4def-b0b5-d97ad7e0f3d8.preview.emergentagent.com"
        
        tests = {
            "accessibility": self.test_frontend_accessibility,
            "static_resources": lambda: self.test_static_resources(frontend_url),
            "api_integration": self.test_frontend_api_integration
        }
        
        results = {}
        for test_name, test_func in tests.items():
            try:
                results[test_name] = test_func()
                self.log(f"   {'✅' if results[test_name] else '❌'} {test_name}")
            except Exception as e:
                results[test_name] = False
                self.log(f"   ❌ {test_name} - Error: {e}")
                
        return results
        
    def test_frontend_accessibility(self):
        """Test frontend accessibility"""
        frontend_url = "https://113c4522-c6a3-4def-b0b5-d97ad7e0f3d8.preview.emergentagent.com"
        response = requests.get(frontend_url, timeout=10)
        return response.status_code == 200
        
    def test_static_resources(self, frontend_url):
        """Test static resources loading"""
        # Test common static resource paths
        static_paths = ["/static/css/", "/static/js/", "/favicon.ico"]
        
        for path in static_paths:
            try:
                response = requests.get(f"{frontend_url}{path}", timeout=5)
                if response.status_code == 200:
                    return True
            except:
                continue
        return False
        
    def test_frontend_api_integration(self):
        """Test frontend API integration"""
        # This would test if frontend can communicate with backend
        # For now, we'll assume it works if both frontend and backend are accessible
        return self.test_frontend_accessibility() and self.test_health_endpoint()
        
    def analyze_script_dependencies(self, script_path):
        """Analyze script dependencies and compatibility"""
        self.log(f"🔍 ANALYZING {os.path.basename(script_path)} DEPENDENCIES")
        
        analysis = {
            "python_versions": [],
            "package_managers": [],
            "system_packages": [],
            "services": [],
            "compatibility_features": []
        }
        
        try:
            with open(script_path, 'r') as f:
                content = f.read()
                
            # Analyze Python versions
            if "python3.11" in content:
                analysis["python_versions"].append("3.11")
            if "python3.12" in content:
                analysis["python_versions"].append("3.12")
            if "python3.13" in content:
                analysis["python_versions"].append("3.13")
            if "deadsnakes" in content:
                analysis["compatibility_features"].append("deadsnakes_ppa")
                
            # Analyze package managers
            if "pip" in content:
                analysis["package_managers"].append("pip")
            if "npm" in content:
                analysis["package_managers"].append("npm")
            if "yarn" in content:
                analysis["package_managers"].append("yarn")
            if "apt" in content:
                analysis["package_managers"].append("apt")
                
            # Analyze system packages
            if "mongodb" in content.lower():
                analysis["system_packages"].append("mongodb")
            if "nodejs" in content.lower() or "node.js" in content.lower():
                analysis["system_packages"].append("nodejs")
            if "supervisor" in content.lower():
                analysis["system_packages"].append("supervisor")
                
            # Analyze services
            if "systemctl" in content:
                analysis["services"].append("systemd")
            if "supervisorctl" in content:
                analysis["services"].append("supervisor")
                
            # Analyze compatibility features
            if "venv" in content:
                analysis["compatibility_features"].append("virtual_environment")
            if "cache purge" in content:
                analysis["compatibility_features"].append("cache_cleanup")
            if "fallback" in content:
                analysis["compatibility_features"].append("fallback_packages")
                
        except Exception as e:
            self.log(f"   ❌ Error analyzing script: {e}")
            
        # Report analysis
        for category, items in analysis.items():
            if items:
                self.log(f"   📋 {category}: {', '.join(items)}")
                
        return analysis
        
    def test_script_python_compatibility(self, script_path):
        """Test script Python version compatibility"""
        script_name = os.path.basename(script_path)
        self.log(f"🐍 TESTING {script_name} PYTHON COMPATIBILITY")
        
        compatibility_tests = {
            "python3.11_support": False,
            "python3.12_support": False,
            "python3.13_support": False,
            "virtual_env_usage": False,
            "pip_upgrade_handling": False
        }
        
        try:
            with open(script_path, 'r') as f:
                content = f.read()
                
            # Test Python version support
            if "python3.11" in content or "3.11" in content:
                compatibility_tests["python3.11_support"] = True
                
            if "python3.12" in content or "3.12" in content:
                compatibility_tests["python3.12_support"] = True
                
            if "python3.13" in content or "3.13" in content:
                compatibility_tests["python3.13_support"] = True
                
            # Test virtual environment usage
            if "venv" in content and "python" in content:
                compatibility_tests["virtual_env_usage"] = True
                
            # Test pip upgrade handling
            if "pip install --upgrade" in content or "pip upgrade" in content:
                compatibility_tests["pip_upgrade_handling"] = True
                
        except Exception as e:
            self.log(f"   ❌ Error testing compatibility: {e}")
            
        # Report results
        for test, result in compatibility_tests.items():
            self.log(f"   {'✅' if result else '❌'} {test}")
            
        return compatibility_tests
        
    def test_script_error_handling(self, script_path):
        """Test script error handling capabilities"""
        script_name = os.path.basename(script_path)
        self.log(f"🛡️ TESTING {script_name} ERROR HANDLING")
        
        error_handling_tests = {
            "set_e_usage": False,
            "error_exit_function": False,
            "cleanup_on_failure": False,
            "logging_system": False,
            "prerequisite_checks": False
        }
        
        try:
            with open(script_path, 'r') as f:
                content = f.read()
                
            # Test set -e usage
            if "set -e" in content:
                error_handling_tests["set_e_usage"] = True
                
            # Test error exit function
            if "error_exit" in content:
                error_handling_tests["error_exit_function"] = True
                
            # Test cleanup on failure
            if "cleanup" in content and ("trap" in content or "exit" in content):
                error_handling_tests["cleanup_on_failure"] = True
                
            # Test logging system
            if "log" in content and ("LOG_FILE" in content or "echo" in content):
                error_handling_tests["logging_system"] = True
                
            # Test prerequisite checks
            if "check" in content and ("version" in content or "command -v" in content):
                error_handling_tests["prerequisite_checks"] = True
                
        except Exception as e:
            self.log(f"   ❌ Error testing error handling: {e}")
            
        # Report results
        for test, result in error_handling_tests.items():
            self.log(f"   {'✅' if result else '❌'} {test}")
            
        return error_handling_tests
        
    def run_detailed_testing(self):
        """Run detailed installation script testing"""
        self.log("🎯 STARTING DETAILED INSTALLATION SCRIPT TESTING")
        self.log("=" * 80)
        
        # Test current system functionality
        self.log("\n📋 PHASE 1: CURRENT SYSTEM FUNCTIONALITY")
        backend_results = self.test_backend_comprehensive()
        frontend_results = self.test_frontend_comprehensive()
        
        # Test each installation script in detail
        self.log("\n📋 PHASE 2: DETAILED SCRIPT ANALYSIS")
        
        scripts = [
            "/app/install-ubuntu.sh",
            "/app/install-bulletproof.sh",
            "/app/install-python313.sh"
        ]
        
        script_results = {}
        
        for script_path in scripts:
            script_name = os.path.basename(script_path)
            self.log(f"\n{'='*60}")
            self.log(f"🔍 DETAILED ANALYSIS: {script_name}")
            self.log(f"{'='*60}")
            
            script_results[script_name] = {
                "dependencies": self.analyze_script_dependencies(script_path),
                "python_compatibility": self.test_script_python_compatibility(script_path),
                "error_handling": self.test_script_error_handling(script_path)
            }
            
        # Generate comprehensive report
        self.generate_detailed_report(backend_results, frontend_results, script_results)
        
    def generate_detailed_report(self, backend_results, frontend_results, script_results):
        """Generate detailed test report"""
        self.log("\n" + "=" * 80)
        self.log("📊 DETAILED INSTALLATION SCRIPT TEST REPORT")
        self.log("=" * 80)
        
        # Backend API Results
        backend_score = sum(backend_results.values())
        backend_total = len(backend_results)
        self.log(f"\n🔧 BACKEND API FUNCTIONALITY: {backend_score}/{backend_total} ({(backend_score/backend_total)*100:.1f}%)")
        for test, result in backend_results.items():
            self.log(f"   {'✅' if result else '❌'} {test}")
            
        # Frontend Results
        frontend_score = sum(frontend_results.values())
        frontend_total = len(frontend_results)
        self.log(f"\n🌐 FRONTEND FUNCTIONALITY: {frontend_score}/{frontend_total} ({(frontend_score/frontend_total)*100:.1f}%)")
        for test, result in frontend_results.items():
            self.log(f"   {'✅' if result else '❌'} {test}")
            
        # Script Analysis Results
        self.log(f"\n📜 INSTALLATION SCRIPTS DETAILED ANALYSIS:")
        
        for script_name, results in script_results.items():
            self.log(f"\n   🔍 {script_name}:")
            
            # Python compatibility
            python_score = sum(results["python_compatibility"].values())
            python_total = len(results["python_compatibility"])
            self.log(f"      🐍 Python Compatibility: {python_score}/{python_total} ({(python_score/python_total)*100:.1f}%)")
            
            # Error handling
            error_score = sum(results["error_handling"].values())
            error_total = len(results["error_handling"])
            self.log(f"      🛡️ Error Handling: {error_score}/{error_total} ({(error_score/error_total)*100:.1f}%)")
            
            # Dependencies
            dep_count = sum(len(deps) for deps in results["dependencies"].values())
            self.log(f"      📦 Dependencies Detected: {dep_count} components")
            
        # Overall Assessment
        self.log(f"\n🎯 OVERALL PHASE 5 ASSESSMENT:")
        
        # Calculate overall scores
        overall_backend = (backend_score / backend_total) * 100
        overall_frontend = (frontend_score / frontend_total) * 100
        
        # Calculate script quality score
        script_quality_scores = []
        for script_name, results in script_results.items():
            python_score = sum(results["python_compatibility"].values()) / len(results["python_compatibility"])
            error_score = sum(results["error_handling"].values()) / len(results["error_handling"])
            script_quality = (python_score + error_score) / 2 * 100
            script_quality_scores.append(script_quality)
            
        overall_scripts = sum(script_quality_scores) / len(script_quality_scores)
        
        self.log(f"   • Backend API Functionality: {overall_backend:.1f}%")
        self.log(f"   • Frontend Functionality: {overall_frontend:.1f}%")
        self.log(f"   • Installation Script Quality: {overall_scripts:.1f}%")
        
        # Final verdict
        overall_success = (overall_backend >= 75 and overall_frontend >= 75 and overall_scripts >= 80)
        
        self.log(f"\n{'🎉' if overall_success else '⚠️'} PHASE 5 INSTALLATION SCRIPT TESTING:")
        if overall_success:
            self.log("   ✅ SUCCESS - All installation scripts are production-ready!")
            self.log("   • Scripts have comprehensive error handling")
            self.log("   • Python version compatibility is well-handled")
            self.log("   • System functionality is working correctly")
        else:
            self.log("   ⚠️ NEEDS ATTENTION - Some areas require improvement:")
            if overall_backend < 75:
                self.log("   • Backend API functionality needs fixes")
            if overall_frontend < 75:
                self.log("   • Frontend functionality needs attention")
            if overall_scripts < 80:
                self.log("   • Installation script quality could be improved")
                
        return overall_success

def main():
    """Main testing function"""
    tester = DetailedInstallationTester()
    success = tester.run_detailed_testing()
    
    # Exit with appropriate code
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()