# 🧪 Test-Framework & Quality Assurance - Vollständige Spezifikation

## 🎯 **Übersicht**

**Kontext**: Umfassende Test-Strategie für das aktienanalyse-ökosystem  
**Ziel**: Produktionsreife Qualitätssicherung mit vollständiger Test-Abdeckung  
**Ansatz**: Multi-Layer-Testing mit automatisierter CI/CD-Integration  

---

## 🏗️ **1. TEST-ARCHITEKTUR OVERVIEW**

### 1.1 **Test-Pyramid-Struktur**
```yaml
# config/test-architecture.yaml

test_pyramid:
  # Unit Tests (70% der Tests)
  unit_tests:
    coverage_target: 90
    execution_time_target: "< 5 minutes"
    frameworks:
      python: "pytest"
      javascript: "jest"
      typescript: "jest + @types/jest"
    
    test_types:
      - function_tests
      - class_tests
      - module_tests
      - pure_logic_tests
    
    scope:
      - business_logic
      - utility_functions
      - data_transformations
      - validation_logic
      - calculations

  # Integration Tests (20% der Tests)
  integration_tests:
    coverage_target: 80
    execution_time_target: "< 15 minutes"
    frameworks:
      api_testing: "pytest + requests"
      database_testing: "pytest + sqlalchemy"
      service_testing: "pytest + httpx"
    
    test_types:
      - api_endpoint_tests
      - database_integration_tests
      - service_to_service_tests
      - event_bus_integration_tests
      - external_api_tests
    
    scope:
      - service_interactions
      - database_operations
      - external_api_calls
      - event_publishing_consuming

  # End-to-End Tests (10% der Tests)
  e2e_tests:
    coverage_target: 60
    execution_time_target: "< 30 minutes"
    frameworks:
      browser_testing: "playwright"
      api_workflow_testing: "pytest + requests"
    
    test_types:
      - user_journey_tests
      - business_workflow_tests
      - cross_service_scenarios
      - real_data_flows
    
    scope:
      - complete_user_workflows
      - business_critical_paths
      - system_integration_scenarios

# Test-Environments
test_environments:
  unit:
    database: "sqlite_memory"
    external_services: "mocked"
    redis: "fakeredis"
    
  integration:
    database: "postgresql_test"
    external_services: "stubbed"
    redis: "redis_test_instance"
    
  e2e:
    database: "postgresql_e2e"
    external_services: "test_environments"
    redis: "redis_e2e_instance"
    
  performance:
    database: "postgresql_perf"
    external_services: "staging_environments"
    redis: "redis_perf_cluster"

# Test-Data-Strategy
test_data_strategy:
  approach: "builder_pattern_with_factories"
  
  data_sources:
    - fixtures: "Static test data for predictable scenarios"
    - factories: "Dynamic test data generation"
    - real_data_samples: "Anonymized production data samples"
    - generated_data: "Synthetic data for edge cases"
  
  data_lifecycle:
    setup: "before_each_test"
    cleanup: "after_each_test"
    isolation: "per_test_transaction_rollback"
```

### 1.2 **Service-spezifische Test-Struktur**
```yaml
# config/service-test-mapping.yaml

service_testing:
  intelligent_core_service:
    test_directories:
      unit: "tests/unit/"
      integration: "tests/integration/"
      e2e: "tests/e2e/"
      performance: "tests/performance/"
    
    critical_test_areas:
      - portfolio_management:
          priority: "critical"
          coverage_target: 95
          test_types: ["unit", "integration", "e2e"]
      
      - risk_calculation:
          priority: "critical"
          coverage_target: 95
          test_types: ["unit", "integration", "performance"]
      
      - asset_analysis:
          priority: "high"
          coverage_target: 85
          test_types: ["unit", "integration"]
      
      - rebalancing_logic:
          priority: "critical"
          coverage_target: 95
          test_types: ["unit", "integration", "e2e"]

  broker_gateway_service:
    critical_test_areas:
      - order_management:
          priority: "critical"
          coverage_target: 95
          test_types: ["unit", "integration", "e2e", "contract"]
      
      - broker_api_integration:
          priority: "critical"
          coverage_target: 90
          test_types: ["integration", "contract", "chaos"]
      
      - market_data_processing:
          priority: "high"
          coverage_target: 85
          test_types: ["unit", "integration", "performance"]

  event_bus_service:
    critical_test_areas:
      - event_processing:
          priority: "critical"
          coverage_target: 95
          test_types: ["unit", "integration", "performance"]
      
      - event_store_operations:
          priority: "critical"
          coverage_target: 95
          test_types: ["unit", "integration", "performance"]
      
      - projection_rebuilding:
          priority: "high"
          coverage_target: 85
          test_types: ["integration", "performance", "chaos"]

  monitoring_service:
    critical_test_areas:
      - metrics_collection:
          priority: "high"
          coverage_target: 85
          test_types: ["unit", "integration"]
      
      - alert_processing:
          priority: "critical"
          coverage_target: 90
          test_types: ["unit", "integration", "e2e"]
      
      - dashboard_data:
          priority: "medium"
          coverage_target: 75
          test_types: ["unit", "integration"]

  frontend_service:
    critical_test_areas:
      - authentication:
          priority: "critical"
          coverage_target: 95
          test_types: ["unit", "integration", "e2e"]
      
      - api_proxy:
          priority: "high"
          coverage_target: 85
          test_types: ["unit", "integration"]
      
      - websocket_gateway:
          priority: "high"
          coverage_target: 85
          test_types: ["unit", "integration", "e2e"]
```

---

## 🔬 **2. UNIT-TEST-STANDARDS**

### 2.1 **Python/pytest-Standards**
```python
# tests/unit/conftest.py - Pytest Configuration
import pytest
import asyncio
from unittest.mock import Mock, patch
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from shared.database.models import Base
from shared.config.settings import TestSettings

# Test-Database-Setup
@pytest.fixture(scope="session")
def test_db_engine():
    """Test-Database-Engine für Unit-Tests"""
    engine = create_engine("sqlite:///:memory:", echo=False)
    Base.metadata.create_all(engine)
    return engine

@pytest.fixture
def db_session(test_db_engine):
    """Database-Session mit automatischem Rollback"""
    connection = test_db_engine.connect()
    transaction = connection.begin()
    
    Session = sessionmaker(bind=connection)
    session = Session()
    
    yield session
    
    session.close()
    transaction.rollback()
    connection.close()

# Mock-Services
@pytest.fixture
def mock_redis():
    """Mock Redis-Client"""
    return Mock()

@pytest.fixture
def mock_broker_api():
    """Mock Broker-API-Client"""
    mock = Mock()
    mock.create_order.return_value = {
        'order_id': 'test-order-123',
        'status': 'pending'
    }
    mock.get_market_data.return_value = {
        'price': 150.25,
        'timestamp': '2024-01-15T10:30:00Z'
    }
    return mock

# Async-Test-Support
@pytest.fixture
def event_loop():
    """Event-Loop für Async-Tests"""
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()

# Test-Settings
@pytest.fixture
def test_settings():
    """Test-spezifische Settings"""
    return TestSettings(
        database_url="sqlite:///:memory:",
        redis_url="redis://localhost:6379/15",
        external_apis_enabled=False,
        debug=True
    )
```

```python
# tests/unit/test_portfolio_service.py - Beispiel Unit-Test
import pytest
from decimal import Decimal
from datetime import datetime, timezone
from unittest.mock import Mock, patch

from services.intelligent_core.portfolio.portfolio_service import PortfolioService
from services.intelligent_core.portfolio.models import Portfolio, Position
from shared.exceptions import InsufficientFundsError, RiskLimitExceededError

class TestPortfolioService:
    """Unit-Tests für PortfolioService"""
    
    @pytest.fixture
    def portfolio_service(self, db_session, mock_redis):
        """PortfolioService-Instanz für Tests"""
        return PortfolioService(db_session=db_session, redis_client=mock_redis)
    
    @pytest.fixture
    def sample_portfolio(self, db_session):
        """Sample-Portfolio für Tests"""
        portfolio = Portfolio(
            portfolio_id="test-portfolio-123",
            name="Test Portfolio",
            currency="EUR",
            cash_balance=Decimal("10000.00"),
            risk_profile="moderate"
        )
        db_session.add(portfolio)
        db_session.commit()
        return portfolio
    
    def test_create_portfolio_success(self, portfolio_service):
        """Test: Portfolio-Erstellung erfolgreich"""
        # Arrange
        portfolio_data = {
            "name": "New Portfolio",
            "currency": "EUR",
            "initial_cash": Decimal("5000.00"),
            "risk_profile": "conservative"
        }
        
        # Act
        portfolio = portfolio_service.create_portfolio(**portfolio_data)
        
        # Assert
        assert portfolio.name == "New Portfolio"
        assert portfolio.currency == "EUR"
        assert portfolio.cash_balance == Decimal("5000.00")
        assert portfolio.risk_profile == "conservative"
        assert portfolio.portfolio_id is not None
        assert portfolio.created_at is not None
    
    def test_create_portfolio_validation_error(self, portfolio_service):
        """Test: Portfolio-Erstellung mit Validierungsfehlern"""
        # Arrange
        invalid_data = {
            "name": "",  # Leerer Name
            "currency": "INVALID",  # Ungültige Währung
            "initial_cash": Decimal("-100.00"),  # Negativer Betrag
            "risk_profile": "unknown"  # Unbekanntes Risk-Profile
        }
        
        # Act & Assert
        with pytest.raises(ValueError) as exc_info:
            portfolio_service.create_portfolio(**invalid_data)
        
        assert "validation" in str(exc_info.value).lower()
    
    def test_calculate_portfolio_value(self, portfolio_service, sample_portfolio, db_session):
        """Test: Portfolio-Wert-Berechnung"""
        # Arrange
        positions = [
            Position(
                portfolio_id=sample_portfolio.portfolio_id,
                asset_symbol="AAPL",
                quantity=Decimal("10.0"),
                average_price=Decimal("150.00")
            ),
            Position(
                portfolio_id=sample_portfolio.portfolio_id,
                asset_symbol="GOOGL",
                quantity=Decimal("5.0"),
                average_price=Decimal("2500.00")
            )
        ]
        
        for position in positions:
            db_session.add(position)
        db_session.commit()
        
        # Mock current prices
        mock_prices = {
            "AAPL": Decimal("155.00"),
            "GOOGL": Decimal("2550.00")
        }
        
        with patch.object(portfolio_service, '_get_current_prices', return_value=mock_prices):
            # Act
            total_value, positions_value, cash_balance = portfolio_service.calculate_portfolio_value(
                sample_portfolio.portfolio_id
            )
        
        # Assert
        expected_positions_value = (Decimal("10.0") * Decimal("155.00")) + (Decimal("5.0") * Decimal("2550.00"))
        expected_total_value = expected_positions_value + sample_portfolio.cash_balance
        
        assert positions_value == expected_positions_value
        assert cash_balance == sample_portfolio.cash_balance
        assert total_value == expected_total_value
    
    def test_rebalance_portfolio_success(self, portfolio_service, sample_portfolio):
        """Test: Portfolio-Rebalancing erfolgreich"""
        # Arrange
        target_allocation = {
            "stocks": Decimal("70.0"),
            "bonds": Decimal("20.0"),
            "cash": Decimal("10.0")
        }
        
        with patch.object(portfolio_service, '_validate_risk_limits', return_value=True), \
             patch.object(portfolio_service, '_execute_rebalancing_orders') as mock_execute:
            
            mock_execute.return_value = {
                "orders_created": 3,
                "estimated_cost": Decimal("25.00")
            }
            
            # Act
            result = portfolio_service.rebalance_portfolio(
                sample_portfolio.portfolio_id,
                target_allocation
            )
        
        # Assert
        assert result["success"] is True
        assert result["orders_created"] == 3
        assert result["estimated_cost"] == Decimal("25.00")
        mock_execute.assert_called_once()
    
    def test_rebalance_portfolio_risk_limit_exceeded(self, portfolio_service, sample_portfolio):
        """Test: Portfolio-Rebalancing mit Risk-Limit-Überschreitung"""
        # Arrange
        risky_allocation = {
            "stocks": Decimal("95.0"),  # Zu hoher Aktienanteil
            "bonds": Decimal("0.0"),
            "cash": Decimal("5.0")
        }
        
        with patch.object(portfolio_service, '_validate_risk_limits', 
                         side_effect=RiskLimitExceededError("Position size exceeds limit")):
            
            # Act & Assert
            with pytest.raises(RiskLimitExceededError):
                portfolio_service.rebalance_portfolio(
                    sample_portfolio.portfolio_id,
                    risky_allocation
                )
    
    @pytest.mark.asyncio
    async def test_async_portfolio_analysis(self, portfolio_service, sample_portfolio):
        """Test: Asynchrone Portfolio-Analyse"""
        # Arrange
        with patch.object(portfolio_service, '_fetch_market_data_async') as mock_fetch:
            mock_fetch.return_value = {
                "market_trends": ["bullish"],
                "risk_indicators": ["low_volatility"]
            }
            
            # Act
            analysis = await portfolio_service.analyze_portfolio_async(
                sample_portfolio.portfolio_id
            )
        
        # Assert
        assert "market_trends" in analysis
        assert "risk_indicators" in analysis
        assert analysis["market_trends"] == ["bullish"]
        mock_fetch.assert_called_once()
    
    def test_portfolio_not_found(self, portfolio_service):
        """Test: Portfolio nicht gefunden"""
        # Act & Assert
        with pytest.raises(ValueError, match="Portfolio not found"):
            portfolio_service.get_portfolio("non-existent-id")
    
    def test_insufficient_funds_error(self, portfolio_service, sample_portfolio):
        """Test: Unzureichende Geldmittel"""
        # Arrange
        large_order_amount = Decimal("50000.00")  # Mehr als verfügbar
        
        # Act & Assert
        with pytest.raises(InsufficientFundsError):
            portfolio_service._validate_sufficient_funds(
                sample_portfolio.portfolio_id,
                large_order_amount
            )
    
    @pytest.mark.parametrize("risk_profile,expected_max_position", [
        ("conservative", Decimal("10.0")),
        ("moderate", Decimal("15.0")),
        ("aggressive", Decimal("25.0"))
    ])
    def test_risk_profile_position_limits(self, portfolio_service, risk_profile, expected_max_position):
        """Test: Risk-Profile-abhängige Positionslimits"""
        # Act
        max_position = portfolio_service._get_max_position_size_for_risk_profile(risk_profile)
        
        # Assert
        assert max_position == expected_max_position

# Performance-Tests
class TestPortfolioServicePerformance:
    """Performance-Tests für PortfolioService"""
    
    def test_portfolio_calculation_performance(self, portfolio_service, db_session):
        """Test: Performance der Portfolio-Berechnung"""
        import time
        
        # Arrange: Portfolio mit vielen Positionen
        portfolio = Portfolio(
            portfolio_id="perf-test-portfolio",
            name="Performance Test Portfolio",
            currency="EUR",
            cash_balance=Decimal("100000.00")
        )
        db_session.add(portfolio)
        
        # 1000 Positionen erstellen
        positions = []
        for i in range(1000):
            position = Position(
                portfolio_id=portfolio.portfolio_id,
                asset_symbol=f"ASSET{i:04d}",
                quantity=Decimal("10.0"),
                average_price=Decimal(f"{100 + i}")
            )
            positions.append(position)
        
        db_session.bulk_save_objects(positions)
        db_session.commit()
        
        # Act: Performance-Messung
        start_time = time.time()
        
        with patch.object(portfolio_service, '_get_current_prices') as mock_prices:
            # Mock prices für alle Assets
            mock_prices.return_value = {f"ASSET{i:04d}": Decimal(f"{105 + i}") for i in range(1000)}
            
            total_value, positions_value, cash_balance = portfolio_service.calculate_portfolio_value(
                portfolio.portfolio_id
            )
        
        end_time = time.time()
        execution_time = end_time - start_time
        
        # Assert: Performance-Ziel < 1 Sekunde für 1000 Positionen
        assert execution_time < 1.0, f"Portfolio calculation took {execution_time:.2f}s (should be < 1.0s)"
        assert total_value > Decimal("0")
```

### 2.2 **JavaScript/Jest-Standards**
```javascript
// tests/unit/frontend/portfolio.test.js
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import { jest } from '@jest/globals';
import PortfolioComponent from '../../../src/components/Portfolio/PortfolioComponent';
import { PortfolioService } from '../../../src/services/PortfolioService';

// Mock External Dependencies
jest.mock('../../../src/services/PortfolioService');
jest.mock('../../../src/hooks/useWebSocket');

describe('PortfolioComponent', () => {
  let mockPortfolioService;
  
  beforeEach(() => {
    // Setup mocks before each test
    mockPortfolioService = {
      getPortfolios: jest.fn(),
      createPortfolio: jest.fn(),
      updatePortfolio: jest.fn(),
      rebalancePortfolio: jest.fn()
    };
    
    PortfolioService.mockImplementation(() => mockPortfolioService);
    
    // Reset all mocks
    jest.clearAllMocks();
  });

  describe('Portfolio Loading', () => {
    test('should display loading state initially', () => {
      // Arrange
      mockPortfolioService.getPortfolios.mockReturnValue(
        new Promise(() => {}) // Pending promise
      );

      // Act
      render(<PortfolioComponent />);

      // Assert
      expect(screen.getByTestId('portfolio-loading')).toBeInTheDocument();
    });

    test('should display portfolios after successful load', async () => {
      // Arrange
      const mockPortfolios = [
        {
          portfolio_id: 'portfolio-1',
          name: 'Test Portfolio 1',
          total_value: 50000.00,
          currency: 'EUR'
        },
        {
          portfolio_id: 'portfolio-2', 
          name: 'Test Portfolio 2',
          total_value: 25000.00,
          currency: 'EUR'
        }
      ];

      mockPortfolioService.getPortfolios.mockResolvedValue({
        success: true,
        data: mockPortfolios
      });

      // Act
      render(<PortfolioComponent />);

      // Assert
      await waitFor(() => {
        expect(screen.getByText('Test Portfolio 1')).toBeInTheDocument();
        expect(screen.getByText('Test Portfolio 2')).toBeInTheDocument();
        expect(screen.getByText('€50,000.00')).toBeInTheDocument();
      });
    });

    test('should display error message on load failure', async () => {
      // Arrange
      mockPortfolioService.getPortfolios.mockRejectedValue(
        new Error('API Error')
      );

      // Act
      render(<PortfolioComponent />);

      // Assert
      await waitFor(() => {
        expect(screen.getByText(/error loading portfolios/i)).toBeInTheDocument();
      });
    });
  });

  describe('Portfolio Creation', () => {
    test('should create portfolio successfully', async () => {
      // Arrange
      const newPortfolio = {
        name: 'New Portfolio',
        currency: 'EUR',
        initial_cash: 10000.00,
        risk_profile: 'moderate'
      };

      mockPortfolioService.createPortfolio.mockResolvedValue({
        success: true,
        data: { ...newPortfolio, portfolio_id: 'new-portfolio-id' }
      });

      mockPortfolioService.getPortfolios.mockResolvedValue({
        success: true,
        data: []
      });

      render(<PortfolioComponent />);

      // Act
      const createButton = screen.getByTestId('create-portfolio-button');
      fireEvent.click(createButton);

      // Fill form
      fireEvent.change(screen.getByLabelText(/portfolio name/i), {
        target: { value: newPortfolio.name }
      });
      fireEvent.change(screen.getByLabelText(/initial cash/i), {
        target: { value: newPortfolio.initial_cash }
      });
      fireEvent.change(screen.getByLabelText(/risk profile/i), {
        target: { value: newPortfolio.risk_profile }
      });

      const submitButton = screen.getByRole('button', { name: /create portfolio/i });
      fireEvent.click(submitButton);

      // Assert
      await waitFor(() => {
        expect(mockPortfolioService.createPortfolio).toHaveBeenCalledWith(newPortfolio);
      });
    });

    test('should handle portfolio creation validation errors', async () => {
      // Arrange
      mockPortfolioService.createPortfolio.mockRejectedValue({
        response: {
          data: {
            success: false,
            error: {
              code: 'VALIDATION_ERROR',
              field_errors: {
                name: 'Name is required',
                initial_cash: 'Must be positive number'
              }
            }
          }
        }
      });

      mockPortfolioService.getPortfolios.mockResolvedValue({
        success: true,
        data: []
      });

      render(<PortfolioComponent />);

      // Act
      const createButton = screen.getByTestId('create-portfolio-button');
      fireEvent.click(createButton);

      const submitButton = screen.getByRole('button', { name: /create portfolio/i });
      fireEvent.click(submitButton);

      // Assert
      await waitFor(() => {
        expect(screen.getByText('Name is required')).toBeInTheDocument();
        expect(screen.getByText('Must be positive number')).toBeInTheDocument();
      });
    });
  });

  describe('Portfolio Rebalancing', () => {
    test('should trigger rebalancing with confirmation', async () => {
      // Arrange
      const portfolio = {
        portfolio_id: 'portfolio-1',
        name: 'Test Portfolio',
        total_value: 50000.00
      };

      mockPortfolioService.getPortfolios.mockResolvedValue({
        success: true,
        data: [portfolio]
      });

      mockPortfolioService.rebalancePortfolio.mockResolvedValue({
        success: true,
        data: { orders_created: 3, estimated_cost: 25.00 }
      });

      // Mock window.confirm
      global.confirm = jest.fn(() => true);

      render(<PortfolioComponent />);

      await waitFor(() => {
        expect(screen.getByText('Test Portfolio')).toBeInTheDocument();
      });

      // Act
      const rebalanceButton = screen.getByTestId(`rebalance-${portfolio.portfolio_id}`);
      fireEvent.click(rebalanceButton);

      // Assert
      expect(global.confirm).toHaveBeenCalledWith(
        expect.stringContaining('rebalance')
      );

      await waitFor(() => {
        expect(mockPortfolioService.rebalancePortfolio).toHaveBeenCalledWith(
          portfolio.portfolio_id,
          expect.any(Object)
        );
      });
    });
  });

  describe('Real-time Updates', () => {
    test('should update portfolio values on WebSocket events', async () => {
      // This test would require mocking the WebSocket hook
      // Implementation depends on WebSocket integration
    });
  });
});

// Portfolio Service Unit Tests
describe('PortfolioService', () => {
  let portfolioService;
  let mockApiClient;

  beforeEach(() => {
    mockApiClient = {
      get: jest.fn(),
      post: jest.fn(),
      put: jest.fn(),
      delete: jest.fn()
    };

    portfolioService = new PortfolioService(mockApiClient);
  });

  describe('getPortfolios', () => {
    test('should fetch portfolios successfully', async () => {
      // Arrange
      const mockResponse = {
        data: {
          success: true,
          data: [
            { portfolio_id: '1', name: 'Portfolio 1' },
            { portfolio_id: '2', name: 'Portfolio 2' }
          ]
        }
      };

      mockApiClient.get.mockResolvedValue(mockResponse);

      // Act
      const result = await portfolioService.getPortfolios();

      // Assert
      expect(mockApiClient.get).toHaveBeenCalledWith('/api/v1/portfolios');
      expect(result.success).toBe(true);
      expect(result.data).toHaveLength(2);
    });

    test('should handle API errors gracefully', async () => {
      // Arrange
      mockApiClient.get.mockRejectedValue(new Error('Network Error'));

      // Act & Assert
      await expect(portfolioService.getPortfolios()).rejects.toThrow('Network Error');
    });
  });

  describe('createPortfolio', () => {
    test('should create portfolio with valid data', async () => {
      // Arrange
      const portfolioData = {
        name: 'New Portfolio',
        currency: 'EUR',
        initial_cash: 10000
      };

      const mockResponse = {
        data: {
          success: true,
          data: { ...portfolioData, portfolio_id: 'new-id' }
        }
      };

      mockApiClient.post.mockResolvedValue(mockResponse);

      // Act
      const result = await portfolioService.createPortfolio(portfolioData);

      // Assert
      expect(mockApiClient.post).toHaveBeenCalledWith(
        '/api/v1/portfolios',
        portfolioData
      );
      expect(result.success).toBe(true);
      expect(result.data.portfolio_id).toBe('new-id');
    });
  });
});

// Test Utilities
export const createMockPortfolio = (overrides = {}) => ({
  portfolio_id: 'mock-portfolio-id',
  name: 'Mock Portfolio',
  currency: 'EUR',
  total_value: 50000.00,
  cash_balance: 5000.00,
  positions: [],
  created_at: '2024-01-15T10:30:00Z',
  ...overrides
});

export const createMockPosition = (overrides = {}) => ({
  position_id: 'mock-position-id',
  asset_symbol: 'AAPL',
  quantity: 10.0,
  average_price: 150.00,
  current_price: 155.00,
  market_value: 1550.00,
  unrealized_pnl: 50.00,
  ...overrides
});
```

---

## 🔗 **3. INTEGRATION-TEST-SUITE**

### 3.1 **Cross-Service-Testing**
```python
# tests/integration/test_cross_service_integration.py
import pytest
import asyncio
import httpx
from datetime import datetime, timezone
from decimal import Decimal

from tests.integration.fixtures import IntegrationTestSetup

class TestCrossServiceIntegration:
    """Integration-Tests für Service-übergreifende Workflows"""
    
    @pytest.fixture(scope="class")
    def integration_setup(self):
        """Setup für Integration-Tests"""
        return IntegrationTestSetup()
    
    @pytest.mark.asyncio
    async def test_portfolio_creation_to_order_flow(self, integration_setup):
        """Test: Vollständiger Workflow von Portfolio-Erstellung bis Order-Ausführung"""
        
        # Step 1: Portfolio erstellen (Core Service)
        portfolio_data = {
            "name": "Integration Test Portfolio",
            "currency": "EUR",
            "initial_cash": 10000.00,
            "risk_profile": "moderate"
        }
        
        async with httpx.AsyncClient() as client:
            # 1. Portfolio erstellen
            portfolio_response = await client.post(
                f"{integration_setup.core_service_url}/api/v1/portfolios",
                json=portfolio_data,
                headers=integration_setup.auth_headers
            )
            
            assert portfolio_response.status_code == 201
            portfolio = portfolio_response.json()["data"]
            portfolio_id = portfolio["portfolio_id"]
            
            # 2. Asset-Analyse abrufen
            analysis_response = await client.get(
                f"{integration_setup.core_service_url}/api/v1/assets/AAPL/analysis",
                headers=integration_setup.auth_headers
            )
            
            assert analysis_response.status_code == 200
            analysis = analysis_response.json()["data"]
            assert analysis["asset_symbol"] == "AAPL"
            
            # 3. Order erstellen (Broker Service)
            order_data = {
                "portfolio_id": portfolio_id,
                "asset_symbol": "AAPL",
                "side": "buy",
                "order_type": "market",
                "quantity": 10.0
            }
            
            order_response = await client.post(
                f"{integration_setup.broker_service_url}/api/v1/orders",
                json=order_data,
                headers=integration_setup.auth_headers
            )
            
            assert order_response.status_code == 201
            order = order_response.json()["data"]
            order_id = order["order_id"]
            
            # 4. Order-Status überwachen
            max_retries = 10
            for _ in range(max_retries):
                order_status_response = await client.get(
                    f"{integration_setup.broker_service_url}/api/v1/orders/{order_id}",
                    headers=integration_setup.auth_headers
                )
                
                order_status = order_status_response.json()["data"]
                
                if order_status["status"] in ["filled", "cancelled", "rejected"]:
                    break
                
                await asyncio.sleep(1)
            
            # 5. Portfolio-Positionen überprüfen
            positions_response = await client.get(
                f"{integration_setup.broker_service_url}/api/v1/positions",
                params={"portfolio_id": portfolio_id},
                headers=integration_setup.auth_headers
            )
            
            assert positions_response.status_code == 200
            positions = positions_response.json()["data"]
            
            # 6. Event-Stream überprüfen (Event Bus Service)
            events_response = await client.get(
                f"{integration_setup.event_bus_url}/api/v1/events",
                params={
                    "stream_name": f"portfolio-{portfolio_id}",
                    "event_type": "OrderCreated"
                },
                headers=integration_setup.auth_headers
            )
            
            assert events_response.status_code == 200
            events = events_response.json()["data"]
            assert len(events) >= 1
            
            # Validate event structure
            order_created_event = events[0]
            assert order_created_event["event_type"] == "OrderCreated"
            assert order_created_event["event_data"]["order_id"] == order_id
    
    @pytest.mark.asyncio
    async def test_risk_limit_enforcement_across_services(self, integration_setup):
        """Test: Risk-Limit-Enforcement über Services hinweg"""
        
        async with httpx.AsyncClient() as client:
            # 1. Portfolio mit niedrigen Risk-Limits erstellen
            portfolio_data = {
                "name": "Risk Test Portfolio",
                "currency": "EUR", 
                "initial_cash": 1000.00,  # Niedriger Betrag
                "risk_profile": "conservative"
            }
            
            portfolio_response = await client.post(
                f"{integration_setup.core_service_url}/api/v1/portfolios",
                json=portfolio_data,
                headers=integration_setup.auth_headers
            )
            
            portfolio_id = portfolio_response.json()["data"]["portfolio_id"]
            
            # 2. Risk-Limits setzen
            risk_limits = {
                "max_position_size_percent": 5.0,  # Maximal 5% pro Position
                "daily_loss_limit_eur": 50.0
            }
            
            await client.put(
                f"{integration_setup.core_service_url}/api/v1/risk/limits",
                json=risk_limits,
                headers=integration_setup.auth_headers
            )
            
            # 3. Versuch einer zu großen Order
            large_order_data = {
                "portfolio_id": portfolio_id,
                "asset_symbol": "AAPL",
                "side": "buy",
                "order_type": "market",
                "quantity": 100.0  # Zu große Position
            }
            
            order_response = await client.post(
                f"{integration_setup.broker_service_url}/api/v1/orders",
                json=large_order_data,
                headers=integration_setup.auth_headers
            )
            
            # 4. Erwarte Fehler wegen Risk-Limit-Überschreitung
            assert order_response.status_code == 422
            error = order_response.json()["error"]
            assert error["code"] == "RISK_LIMIT_EXCEEDED"
            
            # 5. Event-Stream auf Risk-Alert überprüfen
            events_response = await client.get(
                f"{integration_setup.event_bus_url}/api/v1/events",
                params={
                    "event_type": "RiskLimitExceeded"
                },
                headers=integration_setup.auth_headers
            )
            
            risk_events = events_response.json()["data"]
            assert len(risk_events) >= 1
            
            risk_event = risk_events[0]
            assert risk_event["event_data"]["portfolio_id"] == portfolio_id
            assert risk_event["event_data"]["limit_type"] == "position_size"

    @pytest.mark.asyncio
    async def test_event_driven_portfolio_updates(self, integration_setup):
        """Test: Event-getriebene Portfolio-Updates"""
        
        async with httpx.AsyncClient() as client:
            # 1. Portfolio erstellen
            portfolio_response = await client.post(
                f"{integration_setup.core_service_url}/api/v1/portfolios",
                json={
                    "name": "Event Test Portfolio",
                    "currency": "EUR",
                    "initial_cash": 5000.00
                },
                headers=integration_setup.auth_headers
            )
            
            portfolio_id = portfolio_response.json()["data"]["portfolio_id"]
            
            # 2. Event-Subscription erstellen
            subscription_data = {
                "subscriber_name": "test-subscriber",
                "event_types": ["PortfolioUpdated", "OrderStatusChanged"],
                "stream_patterns": [f"portfolio-{portfolio_id}"]
            }
            
            subscription_response = await client.post(
                f"{integration_setup.event_bus_url}/api/v1/subscriptions",
                json=subscription_data,
                headers=integration_setup.auth_headers
            )
            
            assert subscription_response.status_code == 201
            subscription_id = subscription_response.json()["data"]["subscription_id"]
            
            # 3. Portfolio-Update durchführen
            update_data = {
                "name": "Updated Event Test Portfolio",
                "risk_profile": "aggressive"
            }
            
            update_response = await client.put(
                f"{integration_setup.core_service_url}/api/v1/portfolios/{portfolio_id}",
                json=update_data,
                headers=integration_setup.auth_headers
            )
            
            assert update_response.status_code == 200
            
            # 4. Warten auf Event-Verarbeitung
            await asyncio.sleep(2)
            
            # 5. Events überprüfen
            events_response = await client.get(
                f"{integration_setup.event_bus_url}/api/v1/events",
                params={
                    "stream_name": f"portfolio-{portfolio_id}",
                    "event_type": "PortfolioUpdated"
                },
                headers=integration_setup.auth_headers
            )
            
            events = events_response.json()["data"]
            assert len(events) >= 1
            
            update_event = events[0]
            assert update_event["event_data"]["portfolio_id"] == portfolio_id
            assert update_event["event_data"]["updated_fields"]["name"] == "Updated Event Test Portfolio"
            
            # Cleanup: Subscription löschen
            await client.delete(
                f"{integration_setup.event_bus_url}/api/v1/subscriptions/{subscription_id}",
                headers=integration_setup.auth_headers
            )

# Database Integration Tests
class TestDatabaseIntegration:
    """Integration-Tests für Database-Operations"""
    
    @pytest.fixture
    def db_integration_setup(self):
        """Database-Setup für Integration-Tests"""
        return DatabaseIntegrationSetup()
    
    def test_cross_service_transaction_consistency(self, db_integration_setup):
        """Test: Transaktions-Konsistenz über Services hinweg"""
        
        # Test Event-Sourcing Konsistenz
        # Test Read-Model Synchronisation
        # Test Optimistic Locking
        pass
    
    def test_event_store_projections(self, db_integration_setup):
        """Test: Event-Store und Projection-Konsistenz"""
        
        # Test Projection-Rebuild
        # Test Event-Replay
        # Test Materialized View Updates
        pass

# External API Integration Tests
class TestExternalAPIIntegration:
    """Integration-Tests für externe APIs"""
    
    @pytest.mark.integration
    @pytest.mark.external_api
    async def test_bitpanda_api_integration(self):
        """Test: Bitpanda Pro API Integration"""
        
        # Test Market-Data-Fetch
        # Test Order-Placement (Testnet)
        # Test Account-Info-Retrieval
        # Test Error-Handling
        pass
```

### 3.2 **Integration-Test-Fixtures**
```python
# tests/integration/fixtures.py
import pytest
import asyncio
import os
from typing import Dict, Any
import docker
import time

class IntegrationTestSetup:
    """Setup-Klasse für Integration-Tests"""
    
    def __init__(self):
        self.services_started = False
        self.docker_client = docker.from_env()
        self.service_urls = {
            "core": "http://localhost:8001",
            "broker": "http://localhost:8002", 
            "event_bus": "http://localhost:8003",
            "monitoring": "http://localhost:8004",
            "frontend": "https://localhost:8443"
        }
        self.auth_headers = {
            "X-API-Key": "integration-test-api-key",
            "Content-Type": "application/json"
        }
    
    @property
    def core_service_url(self):
        return self.service_urls["core"]
    
    @property 
    def broker_service_url(self):
        return self.service_urls["broker"]
    
    @property
    def event_bus_url(self):
        return self.service_urls["event_bus"]
    
    def start_test_services(self):
        """Startet alle Services für Integration-Tests"""
        
        if self.services_started:
            return
        
        # Docker-Compose für Test-Environment
        compose_file = "tests/integration/docker-compose.test.yml"
        
        # Services starten
        os.system(f"docker-compose -f {compose_file} up -d")
        
        # Warten bis Services bereit sind
        self._wait_for_services_ready()
        
        self.services_started = True
    
    def stop_test_services(self):
        """Stoppt alle Test-Services"""
        
        compose_file = "tests/integration/docker-compose.test.yml"
        os.system(f"docker-compose -f {compose_file} down")
        
        self.services_started = False
    
    def _wait_for_services_ready(self, max_wait_seconds=60):
        """Wartet bis alle Services bereit sind"""
        
        import httpx
        
        start_time = time.time()
        
        while time.time() - start_time < max_wait_seconds:
            all_ready = True
            
            for service_name, service_url in self.service_urls.items():
                if service_name == "frontend":  # HTTPS
                    continue
                    
                try:
                    response = httpx.get(f"{service_url}/health", timeout=5)
                    if response.status_code != 200:
                        all_ready = False
                        break
                except:
                    all_ready = False
                    break
            
            if all_ready:
                print("✅ All services ready for integration tests")
                return
            
            time.sleep(2)
        
        raise RuntimeError("Services did not become ready within timeout")
    
    def create_test_data(self):
        """Erstellt Test-Daten für Integration-Tests"""
        
        # Test-Portfolios erstellen
        # Test-Assets erstellen
        # Test-Market-Data erstellen
        pass
    
    def cleanup_test_data(self):
        """Bereinigt Test-Daten nach Tests"""
        
        # Test-Portfolios löschen
        # Test-Orders stornieren
        # Event-Streams bereinigen
        pass

@pytest.fixture(scope="session")
def integration_setup():
    """Session-weites Integration-Test-Setup"""
    
    setup = IntegrationTestSetup()
    
    # Setup
    setup.start_test_services()
    setup.create_test_data()
    
    yield setup
    
    # Teardown
    setup.cleanup_test_data()
    setup.stop_test_services()

class DatabaseIntegrationSetup:
    """Database-spezifisches Integration-Test-Setup"""
    
    def __init__(self):
        self.test_db_url = "postgresql://test_user:test_pass@localhost:5433/test_aktienanalyse"
        self.redis_url = "redis://localhost:6380/0"
        
    def setup_test_database(self):
        """Erstellt Test-Database-Schema"""
        
        from sqlalchemy import create_engine
        from shared.database.models import Base
        
        engine = create_engine(self.test_db_url)
        Base.metadata.create_all(engine)
        
        return engine
    
    def cleanup_test_database(self):
        """Bereinigt Test-Database"""
        
        from sqlalchemy import create_engine
        from shared.database.models import Base
        
        engine = create_engine(self.test_db_url)
        Base.metadata.drop_all(engine)
```

---

## 🚀 **4. END-TO-END-TEST-FLOWS**

### 4.1 **User-Journey-Tests mit Playwright**
```javascript
// tests/e2e/user-journeys.spec.js
import { test, expect } from '@playwright/test';
import { LoginPage } from '../page-objects/LoginPage';
import { PortfolioPage } from '../page-objects/PortfolioPage';
import { TradingPage } from '../page-objects/TradingPage';

test.describe('Complete User Journeys', () => {
  let loginPage;
  let portfolioPage;
  let tradingPage;

  test.beforeEach(async ({ page }) => {
    loginPage = new LoginPage(page);
    portfolioPage = new PortfolioPage(page);
    tradingPage = new TradingPage(page);
    
    // Setup test data
    await test.step('Setup test environment', async () => {
      await page.goto('/login');
    });
  });

  test('Full Portfolio Management Journey', async ({ page }) => {
    // Step 1: User Login
    await test.step('User logs in successfully', async () => {
      await loginPage.login('test@aktienanalyse.local', 'TestPassword123!');
      await expect(page).toHaveURL('/dashboard');
      await expect(page.locator('[data-testid="user-welcome"]')).toBeVisible();
    });

    // Step 2: Portfolio Creation
    let portfolioId;
    await test.step('User creates new portfolio', async () => {
      await portfolioPage.navigateToPortfolios();
      await portfolioPage.createPortfolio({
        name: 'E2E Test Portfolio',
        initialCash: 10000,
        currency: 'EUR',
        riskProfile: 'moderate'
      });
      
      // Verify portfolio creation
      await expect(page.locator('text=E2E Test Portfolio')).toBeVisible();
      
      // Extract portfolio ID for later steps
      portfolioId = await portfolioPage.getPortfolioId('E2E Test Portfolio');
    });

    // Step 3: Asset Analysis
    await test.step('User analyzes assets', async () => {
      await page.click('[data-testid="analyze-assets-button"]');
      
      // Search for asset
      await page.fill('[data-testid="asset-search"]', 'AAPL');
      await page.click('[data-testid="search-button"]');
      
      // Wait for analysis results
      await expect(page.locator('[data-testid="asset-analysis-AAPL"]')).toBeVisible();
      
      // Check analysis components
      await expect(page.locator('[data-testid="technical-analysis"]')).toBeVisible();
      await expect(page.locator('[data-testid="fundamental-analysis"]')).toBeVisible();
      await expect(page.locator('[data-testid="risk-analysis"]')).toBeVisible();
    });

    // Step 4: Order Placement
    let orderId;
    await test.step('User places buy order', async () => {
      await tradingPage.navigateToTrading();
      
      await tradingPage.createOrder({
        portfolioId: portfolioId,
        assetSymbol: 'AAPL',
        side: 'buy',
        orderType: 'market',
        quantity: 10
      });
      
      // Verify order confirmation
      await expect(page.locator('[data-testid="order-confirmation"]')).toBeVisible();
      
      orderId = await tradingPage.getLastOrderId();
    });

    // Step 5: Order Monitoring
    await test.step('User monitors order execution', async () => {
      await tradingPage.navigateToOrders();
      
      // Check order appears in list
      await expect(page.locator(`[data-testid="order-${orderId}"]`)).toBeVisible();
      
      // Wait for order execution (or timeout)
      await page.waitForSelector(
        `[data-testid="order-${orderId}"] [data-status="filled"]`,
        { timeout: 30000 }
      );
    });

    // Step 6: Portfolio Update Verification
    await test.step('User verifies portfolio update', async () => {
      await portfolioPage.navigateToPortfolios();
      await portfolioPage.selectPortfolio(portfolioId);
      
      // Check position appears
      await expect(page.locator('[data-testid="position-AAPL"]')).toBeVisible();
      
      // Verify position details
      const position = page.locator('[data-testid="position-AAPL"]');
      await expect(position.locator('[data-testid="quantity"]')).toContainText('10');
      await expect(position.locator('[data-testid="symbol"]')).toContainText('AAPL');
    });

    // Step 7: Risk Assessment
    await test.step('User checks risk assessment', async () => {
      await page.click('[data-testid="risk-assessment-button"]');
      
      // Wait for risk calculation
      await expect(page.locator('[data-testid="risk-score"]')).toBeVisible();
      
      // Check risk components
      await expect(page.locator('[data-testid="value-at-risk"]')).toBeVisible();
      await expect(page.locator('[data-testid="concentration-risk"]')).toBeVisible();
    });

    // Step 8: Portfolio Rebalancing
    await test.step('User performs portfolio rebalancing', async () => {
      await portfolioPage.rebalancePortfolio(portfolioId, {
        stocks: 70,
        bonds: 20,
        cash: 10
      });
      
      // Verify rebalancing confirmation
      await expect(page.locator('[data-testid="rebalancing-confirmation"]')).toBeVisible();
      
      // Check generated orders
      await expect(page.locator('[data-testid="rebalancing-orders"]')).toBeVisible();
    });
  });

  test('Risk Management Alert Journey', async ({ page }) => {
    await test.step('User logs in', async () => {
      await loginPage.login('test@aktienanalyse.local', 'TestPassword123!');
    });

    await test.step('User sets strict risk limits', async () => {
      await page.goto('/risk-management');
      
      // Set low risk limits
      await page.fill('[data-testid="max-position-size"]', '5');
      await page.fill('[data-testid="daily-loss-limit"]', '100');
      await page.click('[data-testid="save-risk-limits"]');
      
      await expect(page.locator('[data-testid="risk-limits-saved"]')).toBeVisible();
    });

    await test.step('User attempts risky trade', async () => {
      await tradingPage.navigateToTrading();
      
      // Try to place large order that exceeds risk limits
      await tradingPage.createOrder({
        portfolioId: 'default-portfolio',
        assetSymbol: 'TSLA',
        side: 'buy',
        orderType: 'market',
        quantity: 100 // Large quantity to trigger risk alert
      });
      
      // Expect risk alert
      await expect(page.locator('[data-testid="risk-alert"]')).toBeVisible();
      await expect(page.locator('text=Risk limit exceeded')).toBeVisible();
    });

    await test.step('User receives real-time risk notification', async () => {
      // Check notification appears
      await expect(page.locator('[data-testid="notification-risk-alert"]')).toBeVisible();
      
      // Verify WebSocket real-time update
      await expect(page.locator('[data-testid="risk-dashboard-alert"]')).toBeVisible();
    });
  });

  test('Multi-Portfolio Management Journey', async ({ page }) => {
    await test.step('User logs in', async () => {
      await loginPage.login('test@aktienanalyse.local', 'TestPassword123!');
    });

    // Create multiple portfolios with different strategies
    await test.step('User creates multiple portfolios', async () => {
      const portfolios = [
        { name: 'Conservative Portfolio', riskProfile: 'conservative', cash: 5000 },
        { name: 'Aggressive Portfolio', riskProfile: 'aggressive', cash: 15000 },
        { name: 'Balanced Portfolio', riskProfile: 'moderate', cash: 10000 }
      ];

      for (const portfolio of portfolios) {
        await portfolioPage.createPortfolio({
          name: portfolio.name,
          initialCash: portfolio.cash,
          currency: 'EUR',
          riskProfile: portfolio.riskProfile
        });
        
        await expect(page.locator(`text=${portfolio.name}`)).toBeVisible();
      }
    });

    await test.step('User manages allocation across portfolios', async () => {
      // Switch between portfolios and verify different risk profiles
      for (const portfolioName of ['Conservative Portfolio', 'Aggressive Portfolio']) {
        await portfolioPage.selectPortfolio(portfolioName);
        
        // Verify risk profile specific UI elements
        if (portfolioName.includes('Conservative')) {
          await expect(page.locator('[data-testid="conservative-warning"]')).toBeVisible();
        } else {
          await expect(page.locator('[data-testid="aggressive-features"]')).toBeVisible();
        }
      }
    });
  });

  test('Configuration Management Journey', async ({ page }) => {
    await test.step('User logs in as admin', async () => {
      await loginPage.login('admin@aktienanalyse.local', 'AdminPassword123!');
    });

    await test.step('User navigates to configuration', async () => {
      await page.goto('/configuration');
      
      // Verify configuration sections
      await expect(page.locator('[data-testid="risk-management-config"]')).toBeVisible();
      await expect(page.locator('[data-testid="trading-rules-config"]')).toBeVisible();
      await expect(page.locator('[data-testid="notification-config"]')).toBeVisible();
    });

    await test.step('User modifies trading rules', async () => {
      await page.click('[data-testid="trading-rules-config"]');
      
      // Enable auto-rebalancing
      await page.check('[data-testid="auto-rebalancing-enabled"]');
      await page.fill('[data-testid="rebalancing-threshold"]', '5');
      await page.fill('[data-testid="min-trade-amount"]', '100');
      
      await page.click('[data-testid="save-trading-rules"]');
      
      // Verify save confirmation
      await expect(page.locator('[data-testid="config-saved"]')).toBeVisible();
    });

    await test.step('User verifies configuration applied', async () => {
      // Navigate to portfolio and check if auto-rebalancing is available
      await portfolioPage.navigateToPortfolios();
      
      // Auto-rebalancing button should be visible
      await expect(page.locator('[data-testid="auto-rebalancing-enabled-indicator"]')).toBeVisible();
    });
  });
});

// Error Handling Journeys
test.describe('Error Handling Journeys', () => {
  test('Network Error Recovery Journey', async ({ page }) => {
    // Simulate network failures and test recovery
    await test.step('User experiences network interruption', async () => {
      // Mock network failure
      await page.route('**/api/**', route => route.abort());
      
      await loginPage.login('test@aktienanalyse.local', 'TestPassword123!');
      
      // Should show connection error
      await expect(page.locator('[data-testid="connection-error"]')).toBeVisible();
    });

    await test.step('User recovers from network interruption', async () => {
      // Restore network
      await page.unroute('**/api/**');
      
      // Click retry
      await page.click('[data-testid="retry-connection"]');
      
      // Should recover and show dashboard
      await expect(page).toHaveURL('/dashboard');
    });
  });

  test('Session Expiry Journey', async ({ page }) => {
    await test.step('User session expires', async () => {
      // Login first
      await loginPage.login('test@aktienanalyse.local', 'TestPassword123!');
      
      // Mock session expiry
      await page.route('**/api/**', route => {
        route.fulfill({
          status: 401,
          body: JSON.stringify({
            success: false,
            error: { code: 'SESSION_EXPIRED', message: 'Session expired' }
          })
        });
      });
      
      // Try to access protected resource
      await portfolioPage.navigateToPortfolios();
      
      // Should redirect to login
      await expect(page).toHaveURL('/login');
      await expect(page.locator('[data-testid="session-expired-message"]')).toBeVisible();
    });
  });
});
```

### 4.2 **Page Object Models**
```javascript
// tests/e2e/page-objects/LoginPage.js
export class LoginPage {
  constructor(page) {
    this.page = page;
    this.usernameInput = page.locator('[data-testid="username"]');
    this.passwordInput = page.locator('[data-testid="password"]');
    this.loginButton = page.locator('[data-testid="login-button"]');
    this.errorMessage = page.locator('[data-testid="login-error"]');
  }

  async login(username, password) {
    await this.usernameInput.fill(username);
    await this.passwordInput.fill(password);
    await this.loginButton.click();
  }

  async expectLoginError(message) {
    await expect(this.errorMessage).toBeVisible();
    await expect(this.errorMessage).toContainText(message);
  }
}

// tests/e2e/page-objects/PortfolioPage.js
export class PortfolioPage {
  constructor(page) {
    this.page = page;
  }

  async navigateToPortfolios() {
    await this.page.click('[data-testid="nav-portfolios"]');
    await this.page.waitForURL('**/portfolios');
  }

  async createPortfolio({ name, initialCash, currency, riskProfile }) {
    await this.page.click('[data-testid="create-portfolio-button"]');
    
    await this.page.fill('[data-testid="portfolio-name"]', name);
    await this.page.fill('[data-testid="initial-cash"]', initialCash.toString());
    await this.page.selectOption('[data-testid="currency"]', currency);
    await this.page.selectOption('[data-testid="risk-profile"]', riskProfile);
    
    await this.page.click('[data-testid="submit-portfolio"]');
    
    // Wait for creation confirmation
    await this.page.waitForSelector('[data-testid="portfolio-created"]');
  }

  async selectPortfolio(nameOrId) {
    const selector = `[data-testid="portfolio-${nameOrId}"], [data-portfolio-name="${nameOrId}"]`;
    await this.page.click(selector);
  }

  async rebalancePortfolio(portfolioId, allocation) {
    await this.selectPortfolio(portfolioId);
    await this.page.click('[data-testid="rebalance-button"]');
    
    // Set allocation percentages
    for (const [assetClass, percentage] of Object.entries(allocation)) {
      await this.page.fill(`[data-testid="allocation-${assetClass}"]`, percentage.toString());
    }
    
    await this.page.click('[data-testid="confirm-rebalance"]');
  }

  async getPortfolioId(portfolioName) {
    const portfolioElement = this.page.locator(`[data-portfolio-name="${portfolioName}"]`);
    return await portfolioElement.getAttribute('data-portfolio-id');
  }
}

// tests/e2e/page-objects/TradingPage.js
export class TradingPage {
  constructor(page) {
    this.page = page;
  }

  async navigateToTrading() {
    await this.page.click('[data-testid="nav-trading"]');
    await this.page.waitForURL('**/trading');
  }

  async createOrder({ portfolioId, assetSymbol, side, orderType, quantity, price = null }) {
    await this.page.selectOption('[data-testid="portfolio-select"]', portfolioId);
    await this.page.fill('[data-testid="asset-symbol"]', assetSymbol);
    await this.page.selectOption('[data-testid="order-side"]', side);
    await this.page.selectOption('[data-testid="order-type"]', orderType);
    await this.page.fill('[data-testid="quantity"]', quantity.toString());
    
    if (price && ['limit', 'stop_limit'].includes(orderType)) {
      await this.page.fill('[data-testid="price"]', price.toString());
    }
    
    await this.page.click('[data-testid="place-order"]');
    
    // Wait for order confirmation or error
    const confirmationOrError = this.page.locator(
      '[data-testid="order-confirmation"], [data-testid="order-error"]'
    );
    await confirmationOrError.waitFor();
  }

  async navigateToOrders() {
    await this.page.click('[data-testid="nav-orders"]');
    await this.page.waitForURL('**/orders');
  }

  async getLastOrderId() {
    const lastOrder = this.page.locator('[data-testid^="order-"]:first-child');
    const orderId = await lastOrder.getAttribute('data-testid');
    return orderId.replace('order-', '');
  }

  async cancelOrder(orderId) {
    await this.page.click(`[data-testid="cancel-${orderId}"]`);
    await this.page.click('[data-testid="confirm-cancel"]');
  }
}
```

### 4.3 **API-Workflow-Tests**
```python
# tests/e2e/test_api_workflows.py
import pytest
import asyncio
import httpx
from decimal import Decimal

class TestCompleteAPIWorkflows:
    """End-to-End API-Workflow-Tests"""
    
    @pytest.fixture
    def api_client(self):
        """HTTP-Client für API-Tests"""
        return httpx.AsyncClient(
            base_url="http://localhost:8001",
            headers={
                "X-API-Key": "e2e-test-api-key",
                "Content-Type": "application/json"
            },
            timeout=30.0
        )
    
    @pytest.mark.asyncio
    async def test_complete_trading_workflow_api(self, api_client):
        """Test: Kompletter Trading-Workflow über APIs"""
        
        # Step 1: Portfolio erstellen
        portfolio_response = await api_client.post("/api/v1/portfolios", json={
            "name": "E2E API Test Portfolio",
            "currency": "EUR",
            "initial_cash": 10000.00,
            "risk_profile": "moderate"
        })
        
        assert portfolio_response.status_code == 201
        portfolio = portfolio_response.json()["data"]
        portfolio_id = portfolio["portfolio_id"]
        
        # Step 2: Asset-Analyse abrufen
        analysis_response = await api_client.get("/api/v1/assets/AAPL/analysis")
        assert analysis_response.status_code == 200
        analysis = analysis_response.json()["data"]
        
        # Step 3: Order erstellen (über Broker Gateway)
        broker_client = httpx.AsyncClient(
            base_url="http://localhost:8002",
            headers=api_client.headers
        )
        
        order_response = await broker_client.post("/api/v1/orders", json={
            "portfolio_id": portfolio_id,
            "asset_symbol": "AAPL",
            "side": "buy",
            "order_type": "market",
            "quantity": 10.0
        })
        
        assert order_response.status_code == 201
        order = order_response.json()["data"]
        order_id = order["order_id"]
        
        # Step 4: Order-Status überwachen
        for _ in range(30):  # Max 30 Sekunden warten
            order_status_response = await broker_client.get(f"/api/v1/orders/{order_id}")
            order_status = order_status_response.json()["data"]
            
            if order_status["status"] in ["filled", "cancelled", "rejected"]:
                break
                
            await asyncio.sleep(1)
        
        # Step 5: Portfolio-Positionen überprüfen
        positions_response = await broker_client.get(
            f"/api/v1/positions",
            params={"portfolio_id": portfolio_id}
        )
        
        assert positions_response.status_code == 200
        positions = positions_response.json()["data"]
        
        if order_status["status"] == "filled":
            # Position sollte existieren
            aapl_position = next(
                (pos for pos in positions if pos["asset_symbol"] == "AAPL"),
                None
            )
            assert aapl_position is not None
            assert aapl_position["quantity"] == 10.0
        
        # Step 6: Portfolio-Wert überprüfen
        portfolio_details_response = await api_client.get(f"/api/v1/portfolios/{portfolio_id}")
        assert portfolio_details_response.status_code == 200
        
        portfolio_details = portfolio_details_response.json()["data"]
        assert portfolio_details["total_value"] > 0
        
        # Step 7: Risk-Assessment
        risk_response = await api_client.get(
            f"/api/v1/risk/portfolio/{portfolio_id}/assessment"
        )
        assert risk_response.status_code == 200
        
        risk_assessment = risk_response.json()["data"]
        assert "overall_risk_score" in risk_assessment
        assert "value_at_risk" in risk_assessment
        
        # Step 8: Event-Stream überprüfen
        event_client = httpx.AsyncClient(
            base_url="http://localhost:8003",
            headers=api_client.headers
        )
        
        events_response = await event_client.get(
            "/api/v1/events",
            params={
                "stream_name": f"portfolio-{portfolio_id}",
                "event_type": "OrderCreated"
            }
        )
        
        assert events_response.status_code == 200
        events = events_response.json()["data"]
        assert len(events) >= 1
        
        order_created_event = events[0]
        assert order_created_event["event_type"] == "OrderCreated"
        assert order_created_event["event_data"]["order_id"] == order_id
        
        # Cleanup
        await api_client.delete(f"/api/v1/portfolios/{portfolio_id}")
        await broker_client.aclose()
        await event_client.aclose()
    
    @pytest.mark.asyncio
    async def test_risk_management_workflow_api(self, api_client):
        """Test: Risk-Management-Workflow über APIs"""
        
        # Portfolio mit niedrigen Limits erstellen
        portfolio_response = await api_client.post("/api/v1/portfolios", json={
            "name": "Risk Test Portfolio",
            "currency": "EUR",
            "initial_cash": 1000.00,
            "risk_profile": "conservative"
        })
        
        portfolio_id = portfolio_response.json()["data"]["portfolio_id"]
        
        # Risk-Limits setzen
        risk_limits_response = await api_client.put("/api/v1/risk/limits", json={
            "max_position_size_percent": 5.0,
            "daily_loss_limit_eur": 50.0
        })
        
        assert risk_limits_response.status_code == 200
        
        # Versuch einer zu großen Order
        broker_client = httpx.AsyncClient(
            base_url="http://localhost:8002",
            headers=api_client.headers
        )
        
        large_order_response = await broker_client.post("/api/v1/orders", json={
            "portfolio_id": portfolio_id,
            "asset_symbol": "AAPL",
            "side": "buy",
            "order_type": "market",
            "quantity": 100.0  # Zu große Position
        })
        
        # Erwarte Fehler
        assert large_order_response.status_code == 422
        error = large_order_response.json()["error"]
        assert error["code"] == "RISK_LIMIT_EXCEEDED"
        
        # Event-Stream auf Risk-Event überprüfen
        event_client = httpx.AsyncClient(
            base_url="http://localhost:8003",
            headers=api_client.headers
        )
        
        # Kurz warten für Event-Verarbeitung
        await asyncio.sleep(1)
        
        risk_events_response = await event_client.get(
            "/api/v1/events",
            params={"event_type": "RiskLimitExceeded"}
        )
        
        risk_events = risk_events_response.json()["data"]
        assert len(risk_events) >= 1
        
        risk_event = risk_events[0]
        assert risk_event["event_data"]["portfolio_id"] == portfolio_id
        assert risk_event["event_data"]["limit_type"] == "position_size"
        
        # Cleanup
        await api_client.delete(f"/api/v1/portfolios/{portfolio_id}")
        await broker_client.aclose()
        await event_client.aclose()

    @pytest.mark.asyncio
    async def test_configuration_management_workflow_api(self, api_client):
        """Test: Configuration-Management-Workflow über APIs"""
        
        frontend_client = httpx.AsyncClient(
            base_url="https://localhost:8443",
            headers=api_client.headers,
            verify=False  # Self-signed cert
        )
        
        # Aktuelle Konfiguration abrufen
        config_response = await frontend_client.get("/api/v1/configuration")
        assert config_response.status_code == 200
        
        current_config = config_response.json()["data"]
        
        # Trading-Rules aktualisieren
        updated_trading_rules = {
            "auto_rebalancing_enabled": True,
            "rebalancing_threshold_percent": 5.0,
            "min_trade_amount_eur": 100.0
        }
        
        update_response = await frontend_client.put(
            "/api/v1/configuration/trading_rules",
            json=updated_trading_rules
        )
        
        assert update_response.status_code == 200
        
        # Konfiguration erneut abrufen und Änderungen überprüfen
        updated_config_response = await frontend_client.get("/api/v1/configuration/trading_rules")
        updated_config = updated_config_response.json()["data"]
        
        assert updated_config["auto_rebalancing_enabled"] == True
        assert updated_config["rebalancing_threshold_percent"] == 5.0
        
        await frontend_client.aclose()
```

---

## ⚡ **5. PERFORMANCE-TEST-SPECIFICATIONS**

### 5.1 **Load-Testing mit Locust**
```python
# tests/performance/load_testing.py
from locust import HttpUser, task, between
import random
from decimal import Decimal
import json

class PortfolioManagementUser(HttpUser):
    """Load-Test für Portfolio-Management-Workflows"""
    
    wait_time = between(1, 3)  # 1-3 Sekunden zwischen Requests
    
    def on_start(self):
        """Setup für jeden User"""
        self.portfolio_id = None
        self.auth_headers = {
            "X-API-Key": "load-test-api-key",
            "Content-Type": "application/json"
        }
        
        # Portfolio für Tests erstellen
        self.create_test_portfolio()
    
    def create_test_portfolio(self):
        """Erstellt Test-Portfolio für Load-Tests"""
        portfolio_data = {
            "name": f"Load Test Portfolio {random.randint(1000, 9999)}",
            "currency": "EUR",
            "initial_cash": random.uniform(5000, 50000),
            "risk_profile": random.choice(["conservative", "moderate", "aggressive"])
        }
        
        response = self.client.post(
            "/api/v1/portfolios",
            json=portfolio_data,
            headers=self.auth_headers
        )
        
        if response.status_code == 201:
            self.portfolio_id = response.json()["data"]["portfolio_id"]
    
    @task(3)
    def get_portfolios(self):
        """Häufigste Operation: Portfolio-Liste abrufen"""
        self.client.get(
            "/api/v1/portfolios",
            headers=self.auth_headers,
            name="get_portfolios"
        )
    
    @task(2)
    def get_portfolio_details(self):
        """Portfolio-Details abrufen"""
        if self.portfolio_id:
            self.client.get(
                f"/api/v1/portfolios/{self.portfolio_id}",
                headers=self.auth_headers,
                name="get_portfolio_details"
            )
    
    @task(2)
    def get_asset_analysis(self):
        """Asset-Analyse abrufen (rechenintensiv)"""
        asset_symbol = random.choice(["AAPL", "GOOGL", "MSFT", "TSLA", "AMZN"])
        
        self.client.get(
            f"/api/v1/assets/{asset_symbol}/analysis",
            headers=self.auth_headers,
            name="get_asset_analysis"
        )
    
    @task(1)
    def create_order(self):
        """Order erstellen (kritische Operation)"""
        if not self.portfolio_id:
            return
        
        order_data = {
            "portfolio_id": self.portfolio_id,
            "asset_symbol": random.choice(["AAPL", "GOOGL", "MSFT"]),
            "side": random.choice(["buy", "sell"]),
            "order_type": "market",
            "quantity": random.uniform(1, 20)
        }
        
        # Broker Gateway Service
        self.client.post(
            "http://localhost:8002/api/v1/orders",
            json=order_data,
            headers=self.auth_headers,
            name="create_order"
        )
    
    @task(1)
    def get_risk_assessment(self):
        """Risk-Assessment abrufen (rechenintensiv)"""
        if self.portfolio_id:
            self.client.get(
                f"/api/v1/risk/portfolio/{self.portfolio_id}/assessment",
                headers=self.auth_headers,
                name="get_risk_assessment"
            )
    
    @task(1)
    def get_market_data(self):
        """Market-Data abrufen"""
        asset_symbol = random.choice(["AAPL", "GOOGL", "MSFT", "TSLA"])
        
        # Broker Gateway Service
        self.client.get(
            f"http://localhost:8002/api/v1/market-data/{asset_symbol}/price",
            headers=self.auth_headers,
            name="get_market_data"
        )
    
    def on_stop(self):
        """Cleanup nach Load-Test"""
        if self.portfolio_id:
            self.client.delete(
                f"/api/v1/portfolios/{self.portfolio_id}",
                headers=self.auth_headers
            )

class EventBusLoadUser(HttpUser):
    """Load-Test für Event-Bus-Service"""
    
    host = "http://localhost:8003"
    wait_time = between(0.5, 2)
    
    def on_start(self):
        self.auth_headers = {
            "X-API-Key": "load-test-api-key",
            "Content-Type": "application/json"
        }
    
    @task(4)
    def publish_event(self):
        """Event publizieren"""
        event_data = {
            "stream_name": f"load-test-stream-{random.randint(1, 100)}",
            "event_type": random.choice([
                "PortfolioCreated", "PortfolioUpdated", 
                "OrderCreated", "OrderStatusChanged",
                "PriceUpdate"
            ]),
            "event_data": {
                "test_field": f"test_value_{random.randint(1, 1000)}",
                "timestamp": "2024-01-15T10:30:00Z"
            }
        }
        
        self.client.post(
            "/api/v1/events",
            json=event_data,
            headers=self.auth_headers,
            name="publish_event"
        )
    
    @task(2)
    def get_events(self):
        """Events abrufen"""
        params = {
            "limit": random.randint(10, 100),
            "event_type": random.choice(["PortfolioCreated", "OrderCreated"])
        }
        
        self.client.get(
            "/api/v1/events",
            params=params,
            headers=self.auth_headers,
            name="get_events"
        )
    
    @task(1)
    def create_subscription(self):
        """Event-Subscription erstellen"""
        subscription_data = {
            "subscriber_name": f"load-test-subscriber-{random.randint(1, 1000)}",
            "event_types": random.sample([
                "PortfolioCreated", "PortfolioUpdated",
                "OrderCreated", "OrderStatusChanged"
            ], random.randint(1, 3))
        }
        
        self.client.post(
            "/api/v1/subscriptions",
            json=subscription_data,
            headers=self.auth_headers,
            name="create_subscription"
        )
```

### 5.2 **Stress-Testing-Konfiguration**
```yaml
# tests/performance/stress-test-config.yaml

stress_testing:
  scenarios:
    normal_load:
      description: "Normale Betriebslast"
      users: 100
      spawn_rate: 10
      duration: "5m"
      
    peak_load:
      description: "Spitzenlast (Trading-Stunden)"
      users: 500
      spawn_rate: 25
      duration: "10m"
      
    stress_load:
      description: "Stress-Test bis Breaking-Point"
      users: 1000
      spawn_rate: 50
      duration: "15m"
      
    spike_load:
      description: "Plötzlicher Lastanstieg"
      users: 200
      spawn_rate: 100  # Sehr schneller Anstieg
      duration: "2m"
      
    endurance_load:
      description: "Dauerlast-Test"
      users: 150
      spawn_rate: 5
      duration: "2h"

  performance_targets:
    response_times:
      p50: "< 200ms"    # 50% der Requests
      p95: "< 500ms"    # 95% der Requests
      p99: "< 1000ms"   # 99% der Requests
      max: "< 5000ms"   # Absolutes Maximum
      
    throughput:
      requests_per_second: "> 1000"
      orders_per_minute: "> 500"
      events_per_second: "> 2000"
      
    error_rates:
      http_errors: "< 1%"
      timeouts: "< 0.1%"
      connection_errors: "< 0.05%"
      
    resource_usage:
      cpu_usage: "< 80%"
      memory_usage: "< 80%"
      disk_io: "< 70%"
      network_io: "< 60%"

  monitoring_during_tests:
    metrics_collection_interval: "5s"
    
    system_metrics:
      - cpu_usage_percent
      - memory_usage_percent
      - disk_io_utilization
      - network_io_utilization
      - open_file_descriptors
      - active_connections
      
    application_metrics:
      - response_time_percentiles
      - request_rate
      - error_rate
      - active_sessions
      - database_connections
      - redis_connections
      - event_queue_size
      
    business_metrics:
      - portfolios_created_per_minute
      - orders_processed_per_minute
      - risk_assessments_per_minute
      - events_published_per_second

  alert_thresholds:
    critical:
      - "response_time_p95 > 1000ms"
      - "error_rate > 5%"
      - "cpu_usage > 90%"
      - "memory_usage > 90%"
      
    warning:
      - "response_time_p95 > 500ms"
      - "error_rate > 1%"
      - "cpu_usage > 80%"
      - "memory_usage > 80%"
```

### 5.3 **Database-Performance-Tests**
```python
# tests/performance/test_database_performance.py
import pytest
import time
import asyncio
import asyncpg
from decimal import Decimal
from datetime import datetime, timezone

class TestDatabasePerformance:
    """Performance-Tests für Database-Operations"""
    
    @pytest.fixture
    async def db_pool(self):
        """Database-Connection-Pool für Performance-Tests"""
        pool = await asyncpg.create_pool(
            "postgresql://test_user:test_pass@localhost:5432/test_aktienanalyse",
            min_size=10,
            max_size=50
        )
        yield pool
        await pool.close()
    
    @pytest.mark.asyncio
    async def test_portfolio_query_performance(self, db_pool):
        """Test: Portfolio-Query-Performance"""
        
        # Test-Daten erstellen (1000 Portfolios)
        async with db_pool.acquire() as conn:
            await self._create_test_portfolios(conn, 1000)
            
            # Performance-Messung
            start_time = time.time()
            
            portfolios = await conn.fetch(
                "SELECT * FROM portfolios ORDER BY created_at DESC LIMIT 100"
            )
            
            end_time = time.time()
            query_time = end_time - start_time
            
            # Performance-Ziel: < 50ms für 100 Portfolios aus 1000
            assert query_time < 0.05, f"Portfolio query took {query_time:.3f}s (should be < 0.05s)"
            assert len(portfolios) == 100
    
    @pytest.mark.asyncio
    async def test_position_aggregation_performance(self, db_pool):
        """Test: Position-Aggregation-Performance"""
        
        async with db_pool.acquire() as conn:
            # Test-Daten: Portfolio mit 500 Positionen
            portfolio_id = await self._create_test_portfolio_with_positions(conn, 500)
            
            start_time = time.time()
            
            # Komplexe Aggregation
            result = await conn.fetchrow("""
                SELECT 
                    p.portfolio_id,
                    COUNT(pos.position_id) as position_count,
                    SUM(pos.quantity * pos.current_price) as total_value,
                    AVG(pos.unrealized_pnl_percent) as avg_pnl_percent
                FROM portfolios p
                LEFT JOIN positions pos ON p.portfolio_id = pos.portfolio_id
                WHERE p.portfolio_id = $1
                GROUP BY p.portfolio_id
            """, portfolio_id)
            
            end_time = time.time()
            query_time = end_time - start_time
            
            # Performance-Ziel: < 100ms für 500 Positionen
            assert query_time < 0.1, f"Position aggregation took {query_time:.3f}s (should be < 0.1s)"
            assert result['position_count'] == 500
    
    @pytest.mark.asyncio
    async def test_event_store_write_performance(self, db_pool):
        """Test: Event-Store-Write-Performance"""
        
        async with db_pool.acquire() as conn:
            events_to_write = 1000
            
            start_time = time.time()
            
            # Batch-Insert von Events
            events_data = [
                (
                    f"stream-{i // 10}",  # 10 Events pro Stream
                    f"TestEvent{i}",
                    f'{{"test_data": "value_{i}"}}',
                    datetime.now(timezone.utc),
                    i + 1
                )
                for i in range(events_to_write)
            ]
            
            await conn.executemany(
                "INSERT INTO event_store (stream_name, event_type, event_data, timestamp, sequence_number) VALUES ($1, $2, $3, $4, $5)",
                events_data
            )
            
            end_time = time.time()
            write_time = end_time - start_time
            
            # Performance-Ziel: < 1s für 1000 Events
            assert write_time < 1.0, f"Event store write took {write_time:.3f}s (should be < 1.0s)"
            
            # Throughput-Ziel: > 1000 Events/s
            throughput = events_to_write / write_time
            assert throughput > 1000, f"Event throughput {throughput:.0f} events/s (should be > 1000)"
    
    @pytest.mark.asyncio
    async def test_concurrent_database_operations(self, db_pool):
        """Test: Concurrent Database-Operations"""
        
        async def create_portfolio_concurrent(conn, index):
            """Erstellt Portfolio concurrent"""
            try:
                await conn.execute(
                    "INSERT INTO portfolios (portfolio_id, name, currency, cash_balance) VALUES ($1, $2, $3, $4)",
                    f"concurrent-portfolio-{index}",
                    f"Concurrent Portfolio {index}",
                    "EUR",
                    Decimal("10000.00")
                )
                return True
            except Exception:
                return False
        
        # 100 concurrent Portfolio-Erstellungen
        concurrent_operations = 100
        
        start_time = time.time()
        
        tasks = []
        for i in range(concurrent_operations):
            async with db_pool.acquire() as conn:
                task = create_portfolio_concurrent(conn, i)
                tasks.append(task)
        
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        end_time = time.time()
        total_time = end_time - start_time
        
        successful_operations = sum(1 for r in results if r is True)
        
        # Performance-Ziel: > 50 successful ops/s
        ops_per_second = successful_operations / total_time
        assert ops_per_second > 50, f"Concurrent ops {ops_per_second:.1f} ops/s (should be > 50)"
        
        # Mindestens 90% erfolgreich
        success_rate = successful_operations / concurrent_operations
        assert success_rate > 0.9, f"Success rate {success_rate:.2%} (should be > 90%)"
    
    async def _create_test_portfolios(self, conn, count):
        """Erstellt Test-Portfolios"""
        portfolios_data = [
            (
                f"test-portfolio-{i}",
                f"Test Portfolio {i}",
                "EUR",
                Decimal(f"{10000 + i * 1000}")
            )
            for i in range(count)
        ]
        
        await conn.executemany(
            "INSERT INTO portfolios (portfolio_id, name, currency, cash_balance) VALUES ($1, $2, $3, $4)",
            portfolios_data
        )
    
    async def _create_test_portfolio_with_positions(self, conn, position_count):
        """Erstellt Portfolio mit vielen Positionen"""
        portfolio_id = "perf-test-portfolio"
        
        await conn.execute(
            "INSERT INTO portfolios (portfolio_id, name, currency, cash_balance) VALUES ($1, $2, $3, $4)",
            portfolio_id, "Performance Test Portfolio", "EUR", Decimal("100000")
        )
        
        positions_data = [
            (
                f"position-{i}",
                portfolio_id,
                f"ASSET{i:04d}",
                Decimal("10.0"),
                Decimal(f"{100 + i}"),
                Decimal(f"{105 + i}"),
                Decimal(f"{(105 + i) * 10}"),
                Decimal(f"{5 * 10}"),
                Decimal("5.0")
            )
            for i in range(position_count)
        ]
        
        await conn.executemany(
            "INSERT INTO positions (position_id, portfolio_id, asset_symbol, quantity, average_price, current_price, market_value, unrealized_pnl, unrealized_pnl_percent) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)",
            positions_data
        )
        
        return portfolio_id
```

---

## 📊 **6. TEST-DATA-MANAGEMENT**

### 6.1 **Test-Data-Factory-Pattern**
```python
# tests/fixtures/data_factories.py
import factory
from factory import fuzzy
from decimal import Decimal
from datetime import datetime, timezone
import uuid

from shared.database.models import Portfolio, Position, Asset, TradingOrder

class AssetFactory(factory.Factory):
    """Factory für Asset-Test-Daten"""
    
    class Meta:
        model = Asset
    
    asset_symbol = factory.Sequence(lambda n: f"TEST{n:04d}")
    name = factory.LazyAttribute(lambda obj: f"Test Asset {obj.asset_symbol}")
    asset_type = fuzzy.FuzzyChoice(['stock', 'etf', 'crypto', 'bond'])
    currency = fuzzy.FuzzyChoice(['EUR', 'USD'])
    isin = factory.LazyAttribute(lambda obj: f"TEST{obj.asset_symbol}123456")
    
    # Market-Data
    current_price = fuzzy.FuzzyDecimal(10.0, 1000.0, 2)
    daily_change_percent = fuzzy.FuzzyDecimal(-10.0, 10.0, 2)
    volume_24h = fuzzy.FuzzyInteger(1000, 1000000)
    market_cap = fuzzy.FuzzyDecimal(1000000.0, 1000000000.0, 0)
    
    # Metadata
    created_at = factory.LazyFunction(lambda: datetime.now(timezone.utc))
    updated_at = factory.LazyAttribute(lambda obj: obj.created_at)
    
    @factory.lazy_attribute
    def description(self):
        return f"Test description for {self.name} ({self.asset_symbol})"

class PortfolioFactory(factory.Factory):
    """Factory für Portfolio-Test-Daten"""
    
    class Meta:
        model = Portfolio
    
    portfolio_id = factory.LazyFunction(lambda: str(uuid.uuid4()))
    name = factory.Sequence(lambda n: f"Test Portfolio {n}")
    description = factory.LazyAttribute(lambda obj: f"Description for {obj.name}")
    
    currency = fuzzy.FuzzyChoice(['EUR', 'USD'])
    cash_balance = fuzzy.FuzzyDecimal(1000.0, 100000.0, 2)
    
    risk_profile = fuzzy.FuzzyChoice(['conservative', 'moderate', 'aggressive'])
    
    # Target-Allocation (sicherstellen dass Summe = 100)
    @factory.lazy_attribute
    def target_allocation(self):
        allocations = {
            'stocks': 60.0,
            'bonds': 30.0,
            'cash': 10.0
        }
        
        if self.risk_profile == 'conservative':
            allocations = {'stocks': 40.0, 'bonds': 50.0, 'cash': 10.0}
        elif self.risk_profile == 'aggressive':
            allocations = {'stocks': 80.0, 'bonds': 10.0, 'cash': 10.0}
        
        return allocations
    
    created_at = factory.LazyFunction(lambda: datetime.now(timezone.utc))
    updated_at = factory.LazyAttribute(lambda obj: obj.created_at)
    
    # User-Association
    created_by = "test-user"

class PositionFactory(factory.Factory):
    """Factory für Position-Test-Daten"""
    
    class Meta:
        model = Position
    
    position_id = factory.LazyFunction(lambda: str(uuid.uuid4()))
    portfolio_id = factory.SubFactory(PortfolioFactory)
    asset_symbol = factory.SubFactory(AssetFactory)
    
    quantity = fuzzy.FuzzyDecimal(1.0, 100.0, 2)
    average_price = fuzzy.FuzzyDecimal(10.0, 500.0, 2)
    
    @factory.lazy_attribute
    def current_price(self):
        # Aktuelle Preis variiert um ±10% vom Kaufpreis
        variation = fuzzy.FuzzyDecimal(0.9, 1.1, 4).fuzz()
        return self.average_price * variation
    
    @factory.lazy_attribute
    def market_value(self):
        return self.quantity * self.current_price
    
    @factory.lazy_attribute
    def unrealized_pnl(self):
        return self.market_value - (self.quantity * self.average_price)
    
    @factory.lazy_attribute
    def unrealized_pnl_percent(self):
        cost_basis = self.quantity * self.average_price
        if cost_basis > 0:
            return (self.unrealized_pnl / cost_basis) * 100
        return Decimal('0.0')
    
    opened_at = factory.LazyFunction(lambda: datetime.now(timezone.utc))
    updated_at = factory.LazyAttribute(lambda obj: obj.opened_at)

class TradingOrderFactory(factory.Factory):
    """Factory für Trading-Order-Test-Daten"""
    
    class Meta:
        model = TradingOrder
    
    order_id = factory.LazyFunction(lambda: str(uuid.uuid4()))
    portfolio_id = factory.SubFactory(PortfolioFactory)
    asset_symbol = factory.SubFactory(AssetFactory)
    
    side = fuzzy.FuzzyChoice(['buy', 'sell'])
    order_type = fuzzy.FuzzyChoice(['market', 'limit', 'stop', 'stop_limit'])
    
    quantity = fuzzy.FuzzyDecimal(1.0, 50.0, 2)
    
    @factory.lazy_attribute
    def price(self):
        # Nur für Limit/Stop-Orders
        if self.order_type in ['limit', 'stop', 'stop_limit']:
            return fuzzy.FuzzyDecimal(10.0, 500.0, 2).fuzz()
        return None
    
    @factory.lazy_attribute
    def stop_price(self):
        # Nur für Stop-Limit-Orders
        if self.order_type == 'stop_limit' and self.price:
            return self.price * Decimal('0.95')  # Stop 5% unter Limit
        return None
    
    status = fuzzy.FuzzyChoice(['pending', 'partially_filled', 'filled', 'cancelled', 'rejected'])
    
    filled_quantity = factory.LazyAttribute(
        lambda obj: obj.quantity if obj.status == 'filled' else Decimal('0.0')
    )
    
    @factory.lazy_attribute
    def average_fill_price(self):
        if self.filled_quantity > 0:
            return fuzzy.FuzzyDecimal(10.0, 500.0, 2).fuzz()
        return None
    
    time_in_force = fuzzy.FuzzyChoice(['GTC', 'IOC', 'FOK', 'DAY'])
    
    created_at = factory.LazyFunction(lambda: datetime.now(timezone.utc))
    updated_at = factory.LazyAttribute(lambda obj: obj.created_at)
    
    created_by = "test-user"

# Spezielle Factory-Traits
class ConservativePortfolioFactory(PortfolioFactory):
    """Factory für konservative Portfolios"""
    
    risk_profile = 'conservative'
    cash_balance = fuzzy.FuzzyDecimal(5000.0, 50000.0, 2)
    
    target_allocation = {
        'stocks': 30.0,
        'bonds': 60.0,
        'cash': 10.0
    }

class AggressivePortfolioFactory(PortfolioFactory):
    """Factory für aggressive Portfolios"""
    
    risk_profile = 'aggressive'
    cash_balance = fuzzy.FuzzyDecimal(10000.0, 200000.0, 2)
    
    target_allocation = {
        'stocks': 85.0,
        'bonds': 5.0,
        'cash': 10.0
    }

class FilledOrderFactory(TradingOrderFactory):
    """Factory für ausgeführte Orders"""
    
    status = 'filled'
    filled_quantity = factory.LazyAttribute(lambda obj: obj.quantity)
    average_fill_price = fuzzy.FuzzyDecimal(10.0, 500.0, 2)

class CryptoAssetFactory(AssetFactory):
    """Factory für Crypto-Assets"""
    
    asset_type = 'crypto'
    asset_symbol = factory.Sequence(lambda n: f"BTC{n}" if n % 3 == 0 else f"ETH{n}" if n % 3 == 1 else f"ADA{n}")
    current_price = fuzzy.FuzzyDecimal(0.01, 50000.0, 8)  # Crypto-Preise können sehr variieren
    daily_change_percent = fuzzy.FuzzyDecimal(-30.0, 30.0, 2)  # Höhere Volatilität

# Builder-Pattern für komplexe Test-Szenarien
class PortfolioBuilder:
    """Builder für komplexe Portfolio-Test-Szenarien"""
    
    def __init__(self):
        self.portfolio = None
        self.positions = []
        self.orders = []
    
    def with_portfolio(self, **kwargs):
        """Erstellt Portfolio mit gegebenen Parametern"""
        self.portfolio = PortfolioFactory(**kwargs)
        return self
    
    def with_conservative_profile(self):
        """Setzt konservatives Risk-Profile"""
        if not self.portfolio:
            self.portfolio = ConservativePortfolioFactory()
        else:
            self.portfolio.risk_profile = 'conservative'
            self.portfolio.target_allocation = {
                'stocks': 30.0, 'bonds': 60.0, 'cash': 10.0
            }
        return self
    
    def with_positions(self, count=5, **position_kwargs):
        """Fügt Positionen hinzu"""
        if not self.portfolio:
            self.portfolio = PortfolioFactory()
        
        for _ in range(count):
            position = PositionFactory(
                portfolio_id=self.portfolio.portfolio_id,
                **position_kwargs
            )
            self.positions.append(position)
        
        return self
    
    def with_crypto_positions(self, count=3):
        """Fügt Crypto-Positionen hinzu"""
        for _ in range(count):
            crypto_asset = CryptoAssetFactory()
            position = PositionFactory(
                portfolio_id=self.portfolio.portfolio_id,
                asset_symbol=crypto_asset.asset_symbol
            )
            self.positions.append(position)
        
        return self
    
    def with_pending_orders(self, count=3):
        """Fügt offene Orders hinzu"""
        if not self.portfolio:
            self.portfolio = PortfolioFactory()
        
        for _ in range(count):
            order = TradingOrderFactory(
                portfolio_id=self.portfolio.portfolio_id,
                status='pending'
            )
            self.orders.append(order)
        
        return self
    
    def with_trading_history(self, order_count=10):
        """Fügt Trading-Historie hinzu"""
        statuses = ['filled', 'filled', 'filled', 'cancelled', 'filled']
        
        for i in range(order_count):
            order = TradingOrderFactory(
                portfolio_id=self.portfolio.portfolio_id,
                status=statuses[i % len(statuses)]
            )
            self.orders.append(order)
        
        return self
    
    def build(self):
        """Erstellt das komplette Test-Szenario"""
        return {
            'portfolio': self.portfolio,
            'positions': self.positions,
            'orders': self.orders
        }
```

Damit ist das **Test-Framework & Quality Assurance** vollständig spezifiziert! 🎉