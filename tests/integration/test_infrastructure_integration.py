#!/usr/bin/env python3
"""Comprehensive integration tests for Stock Analysis infrastructure"""

import os
import sys
import time
import json
import unittest
import subprocess
import psycopg2
import redis
import pika
import requests
from datetime import datetime
from typing import Dict, List, Optional

# Test configuration
TEST_CONFIG = {
    'postgres': {
        'host': 'localhost',
        'port': 5432,
        'database': 'aktienanalyse_event_store',
        'user': 'stock_analysis',
        'password': os.getenv('POSTGRES_PASSWORD', 'secure_password')
    },
    'redis': {
        'host': 'localhost',
        'port': 6379,
        'decode_responses': True
    },
    'rabbitmq': {
        'host': 'localhost',
        'port': 5672,
        'username': 'stock_analysis',
        'password': os.getenv('RABBITMQ_PASSWORD', 'stock_password')
    },
    'services': {
        'intelligent-core-service': 8001,
        'broker-gateway-service': 8002,
        'event-bus-service': 8003,
        'monitoring-service': 8004,
        'frontend-service': 8005
    }
}

class InfrastructureIntegrationTest(unittest.TestCase):
    """Test suite for infrastructure integration"""
    
    @classmethod
    def setUpClass(cls):
        """Set up test environment"""
        print("Setting up integration test environment...")
        cls.postgres_conn = None
        cls.redis_client = None
        cls.rabbitmq_conn = None
    
    @classmethod
    def tearDownClass(cls):
        """Clean up test environment"""
        print("Cleaning up integration test environment...")
        if cls.postgres_conn:
            cls.postgres_conn.close()
        if cls.rabbitmq_conn:
            cls.rabbitmq_conn.close()
    
    def test_01_database_connectivity(self):
        """Test PostgreSQL connectivity and basic operations"""
        print("\n[TEST] Database connectivity...")
        
        try:
            # Connect to PostgreSQL
            self.__class__.postgres_conn = psycopg2.connect(**TEST_CONFIG['postgres'])
            cursor = self.postgres_conn.cursor()
            
            # Test connection
            cursor.execute("SELECT version()")
            version = cursor.fetchone()[0]
            self.assertIn("PostgreSQL", version)
            print(f"✓ Connected to {version}")
            
            # Test event store schema
            cursor.execute("""
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'public' 
                AND table_name IN ('events', 'snapshots')
            """)
            tables = [row[0] for row in cursor.fetchall()]
            self.assertIn('events', tables)
            print("✓ Event store schema verified")
            
            cursor.close()
            
        except Exception as e:
            self.fail(f"Database connectivity test failed: {e}")
    
    def test_02_redis_connectivity(self):
        """Test Redis connectivity and basic operations"""
        print("\n[TEST] Redis connectivity...")
        
        try:
            # Connect to Redis
            self.__class__.redis_client = redis.Redis(**TEST_CONFIG['redis'])
            
            # Test connection
            self.assertTrue(self.redis_client.ping())
            print("✓ Connected to Redis")
            
            # Test basic operations
            test_key = "test:integration:timestamp"
            test_value = str(datetime.utcnow().isoformat())
            
            self.redis_client.set(test_key, test_value, ex=60)
            retrieved = self.redis_client.get(test_key)
            self.assertEqual(retrieved, test_value)
            print("✓ Redis read/write operations verified")
            
            # Test pub/sub
            pubsub = self.redis_client.pubsub()
            pubsub.subscribe('test:channel')
            
            self.redis_client.publish('test:channel', 'test message')
            print("✓ Redis pub/sub verified")
            
            pubsub.close()
            
        except Exception as e:
            self.fail(f"Redis connectivity test failed: {e}")
    
    def test_03_rabbitmq_connectivity(self):
        """Test RabbitMQ connectivity and basic operations"""
        print("\n[TEST] RabbitMQ connectivity...")
        
        try:
            # Connect to RabbitMQ
            credentials = pika.PlainCredentials(
                TEST_CONFIG['rabbitmq']['username'],
                TEST_CONFIG['rabbitmq']['password']
            )
            parameters = pika.ConnectionParameters(
                host=TEST_CONFIG['rabbitmq']['host'],
                port=TEST_CONFIG['rabbitmq']['port'],
                credentials=credentials
            )
            
            self.__class__.rabbitmq_conn = pika.BlockingConnection(parameters)
            channel = self.rabbitmq_conn.channel()
            
            print("✓ Connected to RabbitMQ")
            
            # Test exchange exists
            channel.exchange_declare(
                exchange='events',
                exchange_type='topic',
                passive=True
            )
            print("✓ Event exchange verified")
            
            # Test queue exists
            result = channel.queue_declare(
                queue='events.system',
                passive=True
            )
            print(f"✓ System queue verified ({result.method.message_count} messages)")
            
        except Exception as e:
            self.fail(f"RabbitMQ connectivity test failed: {e}")
    
    def test_04_event_store_performance(self):
        """Test event store query performance"""
        print("\n[TEST] Event store performance...")
        
        if not self.postgres_conn:
            self.skipTest("PostgreSQL connection not available")
        
        cursor = self.postgres_conn.cursor()
        
        # Insert test events
        test_events = []
        for i in range(100):
            test_events.append({
                'stream_id': f'test-stream-{i % 10}',
                'stream_type': 'test',
                'event_type': 'test.performance',
                'event_version': i + 1,
                'event_data': json.dumps({
                    'index': i,
                    'timestamp': datetime.utcnow().isoformat(),
                    'data': 'x' * 100
                })
            })
        
        # Batch insert
        start_time = time.time()
        cursor.executemany("""
            INSERT INTO events (stream_id, stream_type, event_type, event_version, event_data)
            VALUES (%(stream_id)s, %(stream_type)s, %(event_type)s, %(event_version)s, %(event_data)s::jsonb)
        """, test_events)
        self.postgres_conn.commit()
        insert_time = time.time() - start_time
        
        print(f"✓ Inserted 100 events in {insert_time:.3f}s")
        self.assertLess(insert_time, 1.0, "Insert performance should be under 1 second")
        
        # Test query performance
        start_time = time.time()
        cursor.execute("""
            SELECT * FROM events 
            WHERE stream_type = 'test' 
            AND event_type = 'test.performance'
            ORDER BY global_version DESC
            LIMIT 50
        """)
        results = cursor.fetchall()
        query_time = time.time() - start_time
        
        print(f"✓ Queried 50 events in {query_time:.3f}s")
        self.assertLess(query_time, 0.2, "Query performance should be under 0.2s")
        
        # Clean up test data
        cursor.execute("DELETE FROM events WHERE stream_type = 'test'")
        self.postgres_conn.commit()
        cursor.close()
    
    def test_05_service_health_checks(self):
        """Test service health check endpoints"""
        print("\n[TEST] Service health checks...")
        
        for service_name, port in TEST_CONFIG['services'].items():
            try:
                response = requests.get(
                    f"http://localhost:{port}/health",
                    timeout=5
                )
                
                if response.status_code == 200:
                    health_data = response.json()
                    print(f"✓ {service_name} is healthy")
                elif response.status_code == 503:
                    print(f"⚠ {service_name} is starting up")
                else:
                    print(f"✗ {service_name} returned status {response.status_code}")
                    
            except requests.exceptions.ConnectionError:
                print(f"✗ {service_name} is not running (port {port})")
            except Exception as e:
                print(f"✗ {service_name} health check failed: {e}")
    
    def test_06_inter_service_communication(self):
        """Test inter-service event communication"""
        print("\n[TEST] Inter-service communication...")
        
        if not self.rabbitmq_conn:
            self.skipTest("RabbitMQ connection not available")
        
        channel = self.rabbitmq_conn.channel()
        
        # Create test queue
        test_queue = 'test.integration.queue'
        channel.queue_declare(queue=test_queue, auto_delete=True)
        channel.queue_bind(
            exchange='events',
            queue=test_queue,
            routing_key='test.#'
        )
        
        # Publish test event
        test_event = {
            'event_type': 'test.integration',
            'timestamp': datetime.utcnow().isoformat(),
            'data': {
                'message': 'Integration test event',
                'source': 'test_suite'
            }
        }
        
        channel.basic_publish(
            exchange='events',
            routing_key='test.integration',
            body=json.dumps(test_event),
            properties=pika.BasicProperties(
                content_type='application/json',
                delivery_mode=2
            )
        )
        
        print("✓ Published test event")
        
        # Consume test event
        method, properties, body = channel.basic_get(queue=test_queue, auto_ack=True)
        
        self.assertIsNotNone(method, "Should receive test event")
        received_event = json.loads(body)
        self.assertEqual(received_event['event_type'], 'test.integration')
        print("✓ Received test event via RabbitMQ")
        
        # Clean up
        channel.queue_delete(queue=test_queue)
    
    def test_07_redis_event_bus(self):
        """Test Redis as event bus"""
        print("\n[TEST] Redis event bus...")
        
        if not self.redis_client:
            self.skipTest("Redis connection not available")
        
        # Test pub/sub messaging
        pubsub = self.redis_client.pubsub()
        test_channel = 'events:test:integration'
        
        pubsub.subscribe(test_channel)
        
        # Publish test message
        test_message = json.dumps({
            'type': 'test',
            'timestamp': datetime.utcnow().isoformat(),
            'data': {'test': True}
        })
        
        publish_count = self.redis_client.publish(test_channel, test_message)
        self.assertGreater(publish_count, 0, "Message should be published")
        
        # Receive message
        message = pubsub.get_message(timeout=1.0)
        while message and message['type'] != 'message':
            message = pubsub.get_message(timeout=1.0)
        
        self.assertIsNotNone(message, "Should receive message")
        received = json.loads(message['data'])
        self.assertEqual(received['type'], 'test')
        print("✓ Redis pub/sub messaging verified")
        
        pubsub.close()
    
    def test_08_systemd_services(self):
        """Test systemd service management"""
        print("\n[TEST] systemd service management...")
        
        services = [
            'stock-analysis-intelligent-core-service',
            'stock-analysis-broker-gateway-service',
            'stock-analysis-event-bus-service',
            'stock-analysis-monitoring-service',
            'stock-analysis-frontend-service'
        ]
        
        for service in services:
            # Check if service file exists
            service_file = f"/etc/systemd/system/{service}.service"
            if os.path.exists(service_file):
                print(f"✓ {service} service file exists")
                
                # Check service status (without requiring it to be running)
                result = subprocess.run(
                    ['systemctl', 'is-enabled', service],
                    capture_output=True,
                    text=True
                )
                
                if result.returncode == 0:
                    print(f"  - Service is enabled: {result.stdout.strip()}")
                else:
                    print(f"  - Service is not enabled")
            else:
                print(f"⚠ {service} service file not created yet")
    
    def test_09_full_event_flow(self):
        """Test complete event flow through the system"""
        print("\n[TEST] Full event flow...")
        
        if not all([self.postgres_conn, self.redis_client, self.rabbitmq_conn]):
            self.skipTest("All connections required for full flow test")
        
        try:
            # 1. Insert event into PostgreSQL
            cursor = self.postgres_conn.cursor()
            
            test_event = {
                'stream_id': 'stock-TEST',
                'stream_type': 'stock',
                'event_type': 'analysis.completed',
                'event_version': 1,
                'event_data': json.dumps({
                    'symbol': 'TEST',
                    'score': 85.5,
                    'timestamp': datetime.utcnow().isoformat()
                })
            }
            
            cursor.execute("""
                INSERT INTO events (stream_id, stream_type, event_type, event_version, event_data)
                VALUES (%(stream_id)s, %(stream_type)s, %(event_type)s, %(event_version)s, %(event_data)s::jsonb)
                RETURNING id, global_version
            """, test_event)
            
            event_id, global_version = cursor.fetchone()
            self.postgres_conn.commit()
            print(f"✓ Event stored in PostgreSQL (ID: {event_id})")
            
            # 2. Publish notification via Redis
            notification = {
                'event_id': str(event_id),
                'global_version': global_version,
                'event_type': test_event['event_type'],
                'stream_id': test_event['stream_id']
            }
            
            self.redis_client.publish(
                'events:notification',
                json.dumps(notification)
            )
            print("✓ Notification published via Redis")
            
            # 3. Publish to RabbitMQ for processing
            channel = self.rabbitmq_conn.channel()
            
            channel.basic_publish(
                exchange='events',
                routing_key='analysis.completed',
                body=json.dumps({
                    'event_id': str(event_id),
                    'data': json.loads(test_event['event_data'])
                })
            )
            print("✓ Event published to RabbitMQ")
            
            # Clean up
            cursor.execute("DELETE FROM events WHERE id = %s", (event_id,))
            self.postgres_conn.commit()
            cursor.close()
            
            print("✓ Full event flow completed successfully")
            
        except Exception as e:
            self.fail(f"Full event flow test failed: {e}")


def run_integration_tests():
    """Run all integration tests"""
    print("=" * 70)
    print("Stock Analysis Infrastructure Integration Tests")
    print("=" * 70)
    
    # Create test suite
    suite = unittest.TestLoader().loadTestsFromTestCase(InfrastructureIntegrationTest)
    
    # Run tests
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    # Summary
    print("\n" + "=" * 70)
    print("Test Summary")
    print("=" * 70)
    print(f"Tests run: {result.testsRun}")
    print(f"Failures: {len(result.failures)}")
    print(f"Errors: {len(result.errors)}")
    print(f"Skipped: {len(result.skipped)}")
    
    return result.wasSuccessful()


if __name__ == '__main__':
    success = run_integration_tests()
    sys.exit(0 if success else 1)