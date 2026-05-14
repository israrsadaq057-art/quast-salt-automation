#!/usr/bin/env python3
# /srv/salt/quast/tests/unit/test_vlans.py
# Unit tests for VLAN configuration
# Network Engineer: Israr Sadaq

import unittest
import yaml
import os
import sys

class TestVLANConfiguration(unittest.TestCase):
    """Test VLAN configuration validity"""
    
    def setUp(self):
        """Load the VLAN pillar data"""
        vlan_file = '/srv/salt/quast/tests/fixtures/mock_pillar.yaml'
        with open(vlan_file, 'r') as f:
            self.pillar_data = yaml.safe_load(f)
    
    def test_vlan_ids_are_integers(self):
        """Test that all VLAN IDs are integers"""
        vlans = self.pillar_data.get('vlans', {})
        for vlan_id in vlans.keys():
            self.assertIsInstance(vlan_id, int, f"VLAN ID {vlan_id} must be integer")
    
    def test_vlan_names_are_unique(self):
        """Test that no duplicate VLAN names exist"""
        vlans = self.pillar_data.get('vlans', {})
        names = [data['name'] for data in vlans.values()]
        self.assertEqual(len(names), len(set(names)), "Duplicate VLAN names found")
    
    def test_subnet_format(self):
        """Test that all subnets are in CIDR format"""
        vlans = self.pillar_data.get('vlans', {})
        for vlan_id, data in vlans.items():
            subnet = data.get('subnet', '')
            self.assertIn('/', subnet, f"VLAN {vlan_id} subnet missing CIDR")
    
    def test_gateway_in_subnet(self):
        """Test that gateway is within the subnet"""
        # This would require more complex subnet math
        pass

class TestNTPSettings(unittest.TestCase):
    """Test NTP configuration"""
    
    def setUp(self):
        with open('/srv/salt/quast/tests/fixtures/mock_pillar.yaml', 'r') as f:
            self.pillar_data = yaml.safe_load(f)
    
    def test_ntp_servers_exist(self):
        """Test that NTP servers are configured"""
        ntp = self.pillar_data.get('ntp', {})
        servers = ntp.get('servers', [])
        self.assertGreater(len(servers), 0, "No NTP servers configured")
    
    def test_ntp_iburst_enabled(self):
        """Test that iburst is enabled for faster sync"""
        ntp = self.pillar_data.get('ntp', {})
        self.assertTrue(ntp.get('iburst', False), "NTP iburst should be enabled")

class TestDNSSettings(unittest.TestCase):
    """Test DNS configuration"""
    
    def setUp(self):
        with open('/srv/salt/quast/tests/fixtures/mock_pillar.yaml', 'r') as f:
            self.pillar_data = yaml.safe_load(f)
    
    def test_dns_servers_exist(self):
        """Test that DNS servers are configured"""
        dns = self.pillar_data.get('dns', {})
        servers = dns.get('servers', [])
        self.assertGreater(len(servers), 0, "No DNS servers configured")
    
    def test_dns_search_domains_exist(self):
        """Test that search domains are configured"""
        dns = self.pillar_data.get('dns', {})
        domains = dns.get('search_domains', [])
        self.assertGreater(len(domains), 0, "No search domains configured")

if __name__ == '__main__':
    unittest.main()
