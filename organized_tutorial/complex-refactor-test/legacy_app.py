#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Legacy Application - Complex Refactoring Test Case
Multiple architectural issues, poor practices, and technical debt
"""

import os
import sys
import json
import sqlite3
import requests
from datetime import datetime
import logging

# Global variables everywhere - BBMC Issue
DATABASE_PATH = "data.db"
API_URL = "https://api.example.com"
API_KEY = "hardcoded_secret_key_12345"
DEBUG_MODE = True
MAX_RETRIES = 3

# Monolithic class - BBCR Issue
class LegacyApp:
    def __init__(self):
        self.db = None
        self.session = requests.Session()
        self.data = {}
        self.cache = {}
        self.errors = []
        
    def connect_database(self):
        """BBMC: No error handling, hardcoded paths"""
        self.db = sqlite3.connect(DATABASE_PATH)
        self.db.execute("CREATE TABLE IF NOT EXISTS users (id INTEGER, name TEXT, email TEXT)")
        self.db.execute("CREATE TABLE IF NOT EXISTS orders (id INTEGER, user_id INTEGER, amount REAL)")
        
    def fetch_user_data(self, user_id):
        """BBAM Priority 1: Critical data fetching with poor error handling"""
        try:
            response = self.session.get(f"{API_URL}/users/{user_id}", 
                                      headers={"Authorization": f"Bearer {API_KEY}"})
            if response.status_code == 200:
                return response.json()
            else:
                print(f"Error: {response.status_code}")
                return None
        except Exception as e:
            print(f"Exception: {e}")
            return None
            
    def process_orders(self, user_id):
        """BBAM Priority 2: Business logic mixed with data access"""
        cursor = self.db.cursor()
        cursor.execute("SELECT * FROM orders WHERE user_id = ?", (user_id,))
        orders = cursor.fetchall()
        
        total = 0
        for order in orders:
            total += order[2]  # Hardcoded index - BBMC Issue
            
        # Business logic mixed with data access - BBCR Issue
        if total > 1000:
            discount = total * 0.1
            total -= discount
            
        return total
        
    def save_data(self, data):
        """BBMC: No validation, direct database writes"""
        cursor = self.db.cursor()
        cursor.execute("INSERT INTO users (id, name, email) VALUES (?, ?, ?)", 
                      (data['id'], data['name'], data['email']))
        self.db.commit()
        
    def generate_report(self, user_id):
        """BBAM Priority 3: Complex reporting with mixed concerns"""
        user_data = self.fetch_user_data(user_id)
        orders_total = self.process_orders(user_id)
        
        report = {
            "user": user_data,
            "orders_total": orders_total,
            "generated_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "status": "completed"
        }
        
        # File I/O mixed with business logic - BBCR Issue
        with open(f"report_{user_id}.json", "w") as f:
            json.dump(report, f)
            
        return report
        
    def cleanup(self):
        """BBMC: Incomplete cleanup"""
        if self.db:
            self.db.close()

# Global functions - BBMC Issue
def main():
    app = LegacyApp()
    app.connect_database()
    
    user_id = 123
    report = app.generate_report(user_id)
    print(f"Report generated: {report}")
    
    app.cleanup()

if __name__ == "__main__":
    main()
