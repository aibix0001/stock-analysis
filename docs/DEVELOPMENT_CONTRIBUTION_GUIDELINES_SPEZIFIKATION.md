# 👨‍💻 Development & Contribution Guidelines - Vollständige Spezifikation

## 🎯 **Übersicht**

**Kontext**: Umfassende Entwicklungs- und Contribution-Guidelines für aktienanalyse-ökosystem  
**Ziel**: Konsistente Entwicklungsstandards und effiziente Teamzusammenarbeit  
**Ansatz**: Standardisierte Workflows + Code Quality + Automatisierte Tools + Dokumentation  

---

## 📝 **1. CODING-CONVENTIONS & STYLE-GUIDES**

### 1.1 Python Coding Standards

```python
# /opt/aktienanalyse-ökosystem/docs/style_guides/python_style_guide.py
"""Python Coding Conventions für Aktienanalyse-Ökosystem

Basiert auf PEP 8 mit projektspezifischen Ergänzungen.
"""

# ======================================================================================
# IMPORTS & ORGANIZATION
# ======================================================================================

# Standard Library Imports (alphabetisch)
import asyncio
import json
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Union, Any

# Third-Party Imports (alphabetisch)
import aiohttp
import asyncpg
import pydantic
from dataclasses import dataclass

# Local Imports (alphabetisch, relativ zum Projekt-Root)
from shared.database.event_store import EventStoreReader
from shared.redis.client import RedisClient
from services.portfolio.models import Portfolio, PortfolioSnapshot

# ======================================================================================
# NAMING CONVENTIONS
# ======================================================================================

# Klassen: PascalCase
class PortfolioPerformanceCalculator:
    """Beschreibung der Klasse.
    
    Längere Beschreibung mit Details über Zweck und Verwendung.
    """
    pass

# Funktionen/Methoden: snake_case
def calculate_portfolio_performance(portfolio_id: str, start_date: datetime) -> float:
    """Portfolio-Performance berechnen.
    
    Args:
        portfolio_id: UUID des Portfolios
        start_date: Startdatum für Berechnung
        
    Returns:
        Performance in Prozent
        
    Raises:
        ValueError: Wenn Portfolio nicht existiert
        DatabaseError: Bei Datenbankfehlern
    """
    pass

# Variablen: snake_case
portfolio_value_eur = 50000.0
user_preferences = {"theme": "dark", "language": "de"}

# Konstanten: UPPER_CASE
DEFAULT_TIMEOUT_SECONDS = 30
MAX_RETRY_ATTEMPTS = 3
API_BASE_URL = "https://api.bitpanda.com/v1"

# Private Attribute/Methoden: _prefix
class TradingEngine:
    def __init__(self):
        self._api_client = None
        self._last_update = None
    
    def _validate_order(self, order_data: Dict) -> bool:
        """Private Methode für Order-Validierung."""
        pass

# ======================================================================================
# TYPE HINTS & ANNOTATIONS
# ======================================================================================

from typing import Dict, List, Optional, Union, Any, Callable, Awaitable
from dataclasses import dataclass
from enum import Enum

# Enum für Status-Werte
class OrderStatus(Enum):
    PENDING = "pending"
    EXECUTED = "executed"
    CANCELLED = "cancelled"
    FAILED = "failed"

# Dataclass für strukturierte Daten
@dataclass
class TradingOrder:
    """Trading Order Datenstruktur."""
    order_id: str
    symbol: str
    quantity: float
    price_eur: float
    order_type: str
    status: OrderStatus
    created_at: datetime
    executed_at: Optional[datetime] = None
    error_message: Optional[str] = None

# Type Aliases für komplexe Typen
PortfolioData = Dict[str, Union[float, str, List[Dict[str, Any]]]]
EventHandler = Callable[[Dict[str, Any]], Awaitable[None]]

# Funktion Annotations
async def process_trading_order(
    order: TradingOrder,
    api_client: "BrokerAPIClient",
    timeout: Optional[int] = None
) -> Dict[str, Any]:
    """Trading Order verarbeiten.
    
    Args:
        order: Trading Order Objekt
        api_client: Broker API Client Instance
        timeout: Optional timeout in Sekunden
        
    Returns:
        Dictionary mit Verarbeitungsresultat
    """
    pass

# ======================================================================================
# ERROR HANDLING & EXCEPTIONS
# ======================================================================================

# Custom Exceptions mit spezifischen Namen
class PortfolioNotFoundError(Exception):
    """Portfolio konnte nicht gefunden werden."""
    pass

class InsufficientFundsError(Exception):
    """Nicht ausreichende Mittel für Order."""
    pass

class BrokerAPIError(Exception):
    """Fehler bei Broker-API-Aufruf."""
    
    def __init__(self, message: str, status_code: int, response_data: Dict = None):
        super().__init__(message)
        self.status_code = status_code
        self.response_data = response_data or {}

# Error Handling Patterns
async def safe_api_call(func: Callable, *args, **kwargs) -> Optional[Any]:
    """Sichere API-Aufrufe mit standardisiertem Error Handling."""
    try:
        return await func(*args, **kwargs)
    except aiohttp.ClientTimeout:
        logger.error("API call timed out")
        return None
    except aiohttp.ClientError as e:
        logger.error(f"API client error: {e}")
        return None
    except Exception as e:
        logger.error(f"Unexpected error in API call: {e}")
        return None

# ======================================================================================
# LOGGING STANDARDS
# ======================================================================================

import logging
from shared.logging.structured_logger import setup_logging, BusinessLogger

# Logger Setup
logger = logging.getLogger(__name__)
business_logger = BusinessLogger("portfolio_service")

# Logging Levels Verwendung
def process_portfolio_update(portfolio_id: str, new_data: Dict):
    """Portfolio Update verarbeiten."""
    logger.info(f"Processing portfolio update for {portfolio_id}")
    
    try:
        # Verarbeitung...
        logger.debug(f"Portfolio data: {new_data}")
        
        # Business Event loggen
        business_logger.log_portfolio_update(
            portfolio_id=portfolio_id,
            old_value=old_value,
            new_value=new_value,
            change_reason="market_update"
        )
        
        logger.info(f"Portfolio {portfolio_id} successfully updated")
        
    except ValueError as e:
        logger.warning(f"Invalid portfolio data for {portfolio_id}: {e}")
    except Exception as e:
        logger.error(f"Failed to update portfolio {portfolio_id}: {e}", exc_info=True)

# ======================================================================================
# ASYNC/AWAIT PATTERNS
# ======================================================================================

# Async Context Manager
class DatabaseTransaction:
    async def __aenter__(self):
        self.conn = await get_database_connection()
        await self.conn.execute("BEGIN")
        return self.conn
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if exc_type:
            await self.conn.execute("ROLLBACK")
        else:
            await self.conn.execute("COMMIT")
        await self.conn.close()

# Async Iterator
class PortfolioEventStream:
    async def __aiter__(self):
        return self
    
    async def __anext__(self):
        event = await self.get_next_event()
        if event is None:
            raise StopAsyncIteration
        return event

# Concurrency Patterns
async def process_multiple_portfolios(portfolio_ids: List[str]):
    """Mehrere Portfolios parallel verarbeiten."""
    tasks = [
        process_single_portfolio(portfolio_id) 
        for portfolio_id in portfolio_ids
    ]
    
    results = await asyncio.gather(*tasks, return_exceptions=True)
    
    # Ergebnisse auswerten
    successful = []
    failed = []
    
    for i, result in enumerate(results):
        if isinstance(result, Exception):
            failed.append((portfolio_ids[i], result))
        else:
            successful.append((portfolio_ids[i], result))
    
    return {"successful": successful, "failed": failed}

# ======================================================================================
# DOCUMENTATION STANDARDS
# ======================================================================================

class PortfolioAnalyzer:
    """Portfolio-Analyse-Service für Performance-Berechnungen.
    
    Dieser Service bietet umfassende Analyse-Funktionen für Portfolios,
    einschließlich Performance-Berechnung, Risk-Assessment und
    Benchmark-Vergleichen.
    
    Attributes:
        event_store: Event Store für Datenabfragen
        cache_manager: Cache Manager für Performance-Optimierung
        
    Example:
        >>> analyzer = PortfolioAnalyzer(event_store, cache_manager)
        >>> performance = await analyzer.calculate_performance("portfolio-123")
        >>> print(f"Performance: {performance:.2f}%")
    """
    
    def __init__(self, event_store: EventStoreReader, cache_manager: "CacheManager"):
        """Initialize Portfolio Analyzer.
        
        Args:
            event_store: Event Store Instance für Datenabfragen
            cache_manager: Cache Manager für Performance-Optimierung
        """
        self.event_store = event_store
        self.cache_manager = cache_manager
        self.logger = logging.getLogger(f"{__name__}.{self.__class__.__name__}")
    
    async def calculate_performance(
        self, 
        portfolio_id: str, 
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        benchmark: Optional[str] = None
    ) -> Dict[str, float]:
        """Portfolio-Performance berechnen.
        
        Berechnet die absolute und relative Performance des Portfolios
        für den angegebenen Zeitraum. Optional kann ein Benchmark
        für relative Performance-Vergleiche angegeben werden.
        
        Args:
            portfolio_id: UUID des zu analysierenden Portfolios
            start_date: Startdatum für Analyse (default: 30 Tage zurück)
            end_date: Enddatum für Analyse (default: heute)
            benchmark: Optional Benchmark-Symbol (z.B. "SPY", "DAX")
            
        Returns:
            Dictionary mit Performance-Metriken:
            {
                "absolute_return": 12.5,           # % absolute Return
                "annualized_return": 8.3,          # % annualisierte Return
                "volatility": 15.2,                # % Volatilität
                "sharpe_ratio": 1.2,               # Sharpe Ratio
                "max_drawdown": -8.7,              # % Maximum Drawdown
                "benchmark_outperformance": 2.3    # % vs Benchmark (falls angegeben)
            }
            
        Raises:
            PortfolioNotFoundError: Portfolio existiert nicht
            ValueError: Ungültige Datums-Parameter
            DataNotAvailableError: Nicht genügend Daten für Berechnung
            
        Example:
            >>> performance = await analyzer.calculate_performance(
            ...     "portfolio-123",
            ...     start_date=datetime(2024, 1, 1),
            ...     benchmark="SPY"
            ... )
            >>> print(f"Return: {performance['absolute_return']:.2f}%")
        """
        # Implementation...
        pass

# ======================================================================================
# CONFIGURATION & CONSTANTS
# ======================================================================================

# Konfiguration via Dataclass
@dataclass
class TradingConfig:
    """Trading Service Konfiguration."""
    max_order_size_eur: float = 10000.0
    default_timeout_seconds: int = 30
    retry_attempts: int = 3
    risk_limit_percentage: float = 5.0
    enable_paper_trading: bool = False
    
    def validate(self) -> None:
        """Konfiguration validieren."""
        if self.max_order_size_eur <= 0:
            raise ValueError("max_order_size_eur must be positive")
        if self.risk_limit_percentage <= 0 or self.risk_limit_percentage > 100:
            raise ValueError("risk_limit_percentage must be between 0 and 100")

# Konstanten Gruppierung
class APIEndpoints:
    """API Endpoint Konstanten."""
    PORTFOLIO_BASE = "/api/v1/portfolios"
    TRADING_BASE = "/api/v1/trading"
    MARKET_DATA_BASE = "/api/v1/market-data"
    
    @classmethod
    def portfolio_detail(cls, portfolio_id: str) -> str:
        return f"{cls.PORTFOLIO_BASE}/{portfolio_id}"
    
    @classmethod
    def trading_orders(cls, symbol: str) -> str:
        return f"{cls.TRADING_BASE}/orders?symbol={symbol}"

# ======================================================================================
# TESTING PATTERNS
# ======================================================================================

import pytest
from unittest.mock import AsyncMock, MagicMock

# Async Test Patterns
@pytest.mark.asyncio
async def test_portfolio_performance_calculation():
    """Test Portfolio Performance Calculation."""
    # Arrange
    mock_event_store = AsyncMock()
    mock_cache_manager = MagicMock()
    
    mock_event_store.get_portfolio_snapshots.return_value = [
        {"date": "2024-01-01", "value": 10000.0},
        {"date": "2024-01-31", "value": 11000.0}
    ]
    
    analyzer = PortfolioAnalyzer(mock_event_store, mock_cache_manager)
    
    # Act
    result = await analyzer.calculate_performance("test-portfolio")
    
    # Assert
    assert result["absolute_return"] == 10.0
    mock_event_store.get_portfolio_snapshots.assert_called_once()

# Fixture Patterns
@pytest.fixture
async def portfolio_analyzer():
    """Portfolio Analyzer Fixture."""
    event_store = AsyncMock()
    cache_manager = MagicMock()
    return PortfolioAnalyzer(event_store, cache_manager)

@pytest.fixture
async def sample_portfolio_data():
    """Sample Portfolio Data Fixture."""
    return {
        "portfolio_id": "test-123",
        "user_id": "user-456",
        "created_at": datetime.utcnow(),
        "positions": [
            {"symbol": "AAPL", "quantity": 10, "avg_price": 150.0},
            {"symbol": "MSFT", "quantity": 5, "avg_price": 300.0}
        ]
    }
```

### 1.2 TypeScript/JavaScript Coding Standards

```typescript
// /opt/aktienanalyse-ökosystem/docs/style_guides/typescript_style_guide.ts
/**
 * TypeScript Coding Conventions für Aktienanalyse-Ökosystem Frontend
 * 
 * Basiert auf TypeScript ESLint Recommended + Airbnb Style Guide
 */

// ======================================================================================
// IMPORTS & ORGANIZATION
// ======================================================================================

// React & Core Libraries (alphabetisch)
import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { BrowserRouter as Router, Route, Routes, Navigate } from 'react-router-dom';

// Third-Party Libraries (alphabetisch)
import axios from 'axios';
import { format, parseISO } from 'date-fns';
import { de } from 'date-fns/locale';

// UI Components (alphabetisch)
import { Button, Card, Table, Modal, Spinner } from '@/components/ui';
import { PortfolioChart, RiskGauge } from '@/components/charts';

// Local Modules (alphabetisch, relativ)
import { usePortfolio, useMarketData } from '@/hooks';
import { portfolioService, tradingService } from '@/services';
import { Portfolio, TradingOrder, MarketData } from '@/types';
import { formatCurrency, calculatePerformance } from '@/utils';

// ======================================================================================
// TYPE DEFINITIONS
// ======================================================================================

// Interface für Objekt-Typen
interface PortfolioPerformance {
  portfolioId: string;
  absoluteReturn: number;
  annualizedReturn: number;
  volatility: number;
  sharpeRatio: number;
  maxDrawdown: number;
  benchmarkOutperformance?: number;
}

// Type für Union Types
type OrderStatus = 'pending' | 'executed' | 'cancelled' | 'failed';

type AssetClass = 'stocks' | 'bonds' | 'crypto' | 'commodities' | 'real_estate';

// Generic Types
interface APIResponse<T> {
  data: T;
  status: 'success' | 'error';
  message?: string;
  timestamp: string;
}

interface PaginatedResponse<T> extends APIResponse<T[]> {
  pagination: {
    page: number;
    limit: number;
    total: number;
    hasNext: boolean;
    hasPrev: boolean;
  };
}

// Enum für Status-Werte
enum RiskLevel {
  LOW = 'low',
  MEDIUM = 'medium',
  HIGH = 'high',
  CRITICAL = 'critical',
}

// ======================================================================================
// COMPONENT PATTERNS
// ======================================================================================

// Functional Component mit TypeScript
interface PortfolioCardProps {
  portfolio: Portfolio;
  showPerformance?: boolean;
  onEdit?: (portfolioId: string) => void;
  onDelete?: (portfolioId: string) => void;
  className?: string;
}

const PortfolioCard: React.FC<PortfolioCardProps> = ({
  portfolio,
  showPerformance = true,
  onEdit,
  onDelete,
  className = '',
}) => {
  // State mit TypeScript
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [performance, setPerformance] = useState<PortfolioPerformance | null>(null);
  const [error, setError] = useState<string | null>(null);

  // Custom Hooks
  const { data: marketData, isLoading: marketDataLoading } = useMarketData(
    portfolio.positions.map(p => p.symbol)
  );

  // Memoized Values
  const totalValue = useMemo(() => {
    if (!marketData) return 0;
    return portfolio.positions.reduce((sum, position) => {
      const currentPrice = marketData[position.symbol]?.price || position.avgPrice;
      return sum + (position.quantity * currentPrice);
    }, 0);
  }, [portfolio.positions, marketData]);

  // Callbacks
  const handleEdit = useCallback(() => {
    if (onEdit) {
      onEdit(portfolio.id);
    }
  }, [portfolio.id, onEdit]);

  const handleDelete = useCallback(async () => {
    if (!onDelete) return;
    
    setIsLoading(true);
    try {
      await portfolioService.deletePortfolio(portfolio.id);
      onDelete(portfolio.id);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Fehler beim Löschen');
    } finally {
      setIsLoading(false);
    }
  }, [portfolio.id, onDelete]);

  // Effects
  useEffect(() => {
    let isMounted = true;

    const loadPerformance = async () => {
      if (!showPerformance) return;

      setIsLoading(true);
      setError(null);

      try {
        const performanceData = await portfolioService.getPerformance(portfolio.id);
        
        if (isMounted) {
          setPerformance(performanceData);
        }
      } catch (err) {
        if (isMounted) {
          setError(err instanceof Error ? err.message : 'Fehler beim Laden der Performance');
        }
      } finally {
        if (isMounted) {
          setIsLoading(false);
        }
      }
    };

    loadPerformance();

    return () => {
      isMounted = false;
    };
  }, [portfolio.id, showPerformance]);

  // Early returns für Loading/Error States
  if (isLoading && !performance) {
    return (
      <Card className={`portfolio-card ${className}`}>
        <Spinner size="large" />
      </Card>
    );
  }

  if (error) {
    return (
      <Card className={`portfolio-card portfolio-card--error ${className}`}>
        <div className="error-message">
          Fehler: {error}
        </div>
      </Card>
    );
  }

  // Render
  return (
    <Card className={`portfolio-card ${className}`} data-testid="portfolio-card">
      <div className="portfolio-card__header">
        <h3 className="portfolio-card__title">{portfolio.name}</h3>
        <div className="portfolio-card__actions">
          <Button
            variant="ghost"
            size="small"
            onClick={handleEdit}
            aria-label={`Portfolio ${portfolio.name} bearbeiten`}
          >
            Bearbeiten
          </Button>
          <Button
            variant="ghost"
            size="small"
            onClick={handleDelete}
            aria-label={`Portfolio ${portfolio.name} löschen`}
            disabled={isLoading}
          >
            Löschen
          </Button>
        </div>
      </div>

      <div className="portfolio-card__content">
        <div className="portfolio-card__value">
          <span className="label">Gesamtwert:</span>
          <span className="value" data-testid="portfolio-value">
            {formatCurrency(totalValue)}
          </span>
        </div>

        {showPerformance && performance && (
          <div className="portfolio-card__performance">
            <div className="performance-metric">
              <span className="label">Performance:</span>
              <span 
                className={`value ${performance.absoluteReturn >= 0 ? 'positive' : 'negative'}`}
                data-testid="portfolio-performance"
              >
                {performance.absoluteReturn.toFixed(2)}%
              </span>
            </div>
          </div>
        )}
      </div>
    </Card>
  );
};

// ======================================================================================
// CUSTOM HOOKS PATTERNS
// ======================================================================================

// Custom Hook mit TypeScript
interface UsePortfolioOptions {
  enableRealTimeUpdates?: boolean;
  refetchInterval?: number;
}

interface UsePortfolioReturn {
  portfolio: Portfolio | null;
  isLoading: boolean;
  error: string | null;
  refetch: () => Promise<void>;
  updatePortfolio: (updates: Partial<Portfolio>) => Promise<void>;
}

const usePortfolio = (
  portfolioId: string,
  options: UsePortfolioOptions = {}
): UsePortfolioReturn => {
  const {
    enableRealTimeUpdates = false,
    refetchInterval = 30000, // 30 seconds
  } = options;

  const [portfolio, setPortfolio] = useState<Portfolio | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  const fetchPortfolio = useCallback(async () => {
    try {
      setError(null);
      const data = await portfolioService.getPortfolio(portfolioId);
      setPortfolio(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Fehler beim Laden des Portfolios');
    } finally {
      setIsLoading(false);
    }
  }, [portfolioId]);

  const updatePortfolio = useCallback(async (updates: Partial<Portfolio>) => {
    if (!portfolio) return;

    try {
      setError(null);
      const updatedPortfolio = await portfolioService.updatePortfolio(portfolioId, updates);
      setPortfolio(updatedPortfolio);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Fehler beim Aktualisieren des Portfolios');
      throw err;
    }
  }, [portfolioId, portfolio]);

  // Initial fetch
  useEffect(() => {
    fetchPortfolio();
  }, [fetchPortfolio]);

  // Real-time updates
  useEffect(() => {
    if (!enableRealTimeUpdates) return;

    const interval = setInterval(fetchPortfolio, refetchInterval);
    return () => clearInterval(interval);
  }, [enableRealTimeUpdates, refetchInterval, fetchPortfolio]);

  return {
    portfolio,
    isLoading,
    error,
    refetch: fetchPortfolio,
    updatePortfolio,
  };
};

// ======================================================================================
// SERVICE PATTERNS
// ======================================================================================

// API Service mit TypeScript
class PortfolioService {
  private readonly baseURL: string;
  private readonly apiClient: axios.AxiosInstance;

  constructor(baseURL: string) {
    this.baseURL = baseURL;
    this.apiClient = axios.create({
      baseURL,
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Request Interceptor
    this.apiClient.interceptors.request.use(
      (config) => {
        const token = localStorage.getItem('authToken');
        if (token) {
          config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
      },
      (error) => Promise.reject(error)
    );

    // Response Interceptor
    this.apiClient.interceptors.response.use(
      (response) => response,
      (error) => {
        if (error.response?.status === 401) {
          // Handle authentication error
          window.location.href = '/login';
        }
        return Promise.reject(error);
      }
    );
  }

  async getPortfolios(): Promise<Portfolio[]> {
    try {
      const response = await this.apiClient.get<APIResponse<Portfolio[]>>('/portfolios');
      return response.data.data;
    } catch (error) {
      throw new Error(`Fehler beim Laden der Portfolios: ${error}`);
    }
  }

  async getPortfolio(portfolioId: string): Promise<Portfolio> {
    try {
      const response = await this.apiClient.get<APIResponse<Portfolio>>(
        `/portfolios/${portfolioId}`
      );
      return response.data.data;
    } catch (error) {
      throw new Error(`Fehler beim Laden des Portfolios: ${error}`);
    }
  }

  async createPortfolio(portfolioData: Omit<Portfolio, 'id' | 'createdAt' | 'updatedAt'>): Promise<Portfolio> {
    try {
      const response = await this.apiClient.post<APIResponse<Portfolio>>(
        '/portfolios',
        portfolioData
      );
      return response.data.data;
    } catch (error) {
      throw new Error(`Fehler beim Erstellen des Portfolios: ${error}`);
    }
  }

  async updatePortfolio(
    portfolioId: string,
    updates: Partial<Portfolio>
  ): Promise<Portfolio> {
    try {
      const response = await this.apiClient.patch<APIResponse<Portfolio>>(
        `/portfolios/${portfolioId}`,
        updates
      );
      return response.data.data;
    } catch (error) {
      throw new Error(`Fehler beim Aktualisieren des Portfolios: ${error}`);
    }
  }

  async deletePortfolio(portfolioId: string): Promise<void> {
    try {
      await this.apiClient.delete(`/portfolios/${portfolioId}`);
    } catch (error) {
      throw new Error(`Fehler beim Löschen des Portfolios: ${error}`);
    }
  }

  async getPerformance(portfolioId: string): Promise<PortfolioPerformance> {
    try {
      const response = await this.apiClient.get<APIResponse<PortfolioPerformance>>(
        `/portfolios/${portfolioId}/performance`
      );
      return response.data.data;
    } catch (error) {
      throw new Error(`Fehler beim Laden der Performance: ${error}`);
    }
  }
}

// ======================================================================================
// UTILITY FUNCTIONS
// ======================================================================================

// Utility Functions mit TypeScript
const formatCurrency = (amount: number, currency: string = 'EUR'): string => {
  return new Intl.NumberFormat('de-DE', {
    style: 'currency',
    currency,
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount);
};

const formatPercentage = (value: number, decimals: number = 2): string => {
  return `${value.toFixed(decimals)}%`;
};

const calculatePercentageChange = (oldValue: number, newValue: number): number => {
  if (oldValue === 0) return 0;
  return ((newValue - oldValue) / oldValue) * 100;
};

// Type Guards
const isPortfolio = (obj: any): obj is Portfolio => {
  return obj && typeof obj.id === 'string' && typeof obj.name === 'string';
};

const isTradingOrder = (obj: any): obj is TradingOrder => {
  return obj && typeof obj.orderId === 'string' && typeof obj.symbol === 'string';
};

// ======================================================================================
// TESTING PATTERNS
// ======================================================================================

// Component Testing mit React Testing Library
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { vi } from 'vitest';

describe('PortfolioCard', () => {
  const mockPortfolio: Portfolio = {
    id: 'test-portfolio-123',
    name: 'Test Portfolio',
    positions: [
      { symbol: 'AAPL', quantity: 10, avgPrice: 150 },
      { symbol: 'MSFT', quantity: 5, avgPrice: 300 },
    ],
    createdAt: '2024-01-01T00:00:00Z',
    updatedAt: '2024-01-01T00:00:00Z',
  };

  const mockProps: PortfolioCardProps = {
    portfolio: mockPortfolio,
    showPerformance: true,
    onEdit: vi.fn(),
    onDelete: vi.fn(),
  };

  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should render portfolio name and value', () => {
    render(<PortfolioCard {...mockProps} />);
    
    expect(screen.getByText('Test Portfolio')).toBeInTheDocument();
    expect(screen.getByTestId('portfolio-value')).toBeInTheDocument();
  });

  it('should call onEdit when edit button is clicked', () => {
    render(<PortfolioCard {...mockProps} />);
    
    const editButton = screen.getByLabelText(/Portfolio.*bearbeiten/);
    fireEvent.click(editButton);
    
    expect(mockProps.onEdit).toHaveBeenCalledWith('test-portfolio-123');
  });

  it('should show loading state when performance is being fetched', async () => {
    // Mock loading state
    vi.mocked(portfolioService.getPerformance).mockImplementation(
      () => new Promise(resolve => setTimeout(resolve, 1000))
    );

    render(<PortfolioCard {...mockProps} />);
    
    expect(screen.getByRole('status')).toBeInTheDocument(); // Spinner
  });

  it('should display error message when performance fetch fails', async () => {
    vi.mocked(portfolioService.getPerformance).mockRejectedValue(
      new Error('API Error')
    );

    render(<PortfolioCard {...mockProps} />);
    
    await waitFor(() => {
      expect(screen.getByText(/Fehler/)).toBeInTheDocument();
    });
  });
});

// Export for other modules
export { PortfolioCard, usePortfolio, PortfolioService };
export type { PortfolioCardProps, UsePortfolioOptions, UsePortfolioReturn };
```

### 1.3 SQL Coding Standards

```sql
-- /opt/aktienanalyse-ökosystem/docs/style_guides/sql_style_guide.sql
-- SQL Coding Conventions für Aktienanalyse-Ökosystem
-- Basiert auf SQL Style Guide von Simon Holywell

-- ======================================================================================
-- NAMING CONVENTIONS
-- ======================================================================================

-- Tabellen: snake_case, Plural
CREATE TABLE portfolios (
    portfolio_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    portfolio_name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE portfolio_positions (
    position_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    portfolio_id UUID NOT NULL REFERENCES portfolios(portfolio_id),
    asset_symbol VARCHAR(20) NOT NULL,
    quantity DECIMAL(20, 8) NOT NULL,
    average_price_eur DECIMAL(15, 4) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indizes: idx_table_column(s)
CREATE INDEX idx_portfolios_user_id ON portfolios(user_id);
CREATE INDEX idx_portfolio_positions_portfolio_id ON portfolio_positions(portfolio_id);
CREATE INDEX idx_portfolio_positions_symbol ON portfolio_positions(asset_symbol);

-- Views: vw_purpose
CREATE VIEW vw_portfolio_summary AS
SELECT 
    p.portfolio_id,
    p.portfolio_name,
    p.user_id,
    COUNT(pp.position_id) AS position_count,
    SUM(pp.quantity * pp.average_price_eur) AS total_value_eur,
    p.created_at,
    p.updated_at
FROM portfolios p
LEFT JOIN portfolio_positions pp ON p.portfolio_id = pp.portfolio_id
GROUP BY p.portfolio_id, p.portfolio_name, p.user_id, p.created_at, p.updated_at;

-- Funktionen: snake_case
CREATE OR REPLACE FUNCTION calculate_portfolio_performance(
    p_portfolio_id UUID,
    p_start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
    p_end_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE(
    performance_date DATE,
    portfolio_value_eur DECIMAL(15, 4),
    daily_return_percent DECIMAL(8, 4),
    cumulative_return_percent DECIMAL(8, 4)
) AS $$
BEGIN
    RETURN QUERY
    WITH daily_values AS (
        SELECT 
            ps.snapshot_date,
            ps.total_value_eur,
            LAG(ps.total_value_eur) OVER (ORDER BY ps.snapshot_date) AS prev_value
        FROM portfolio_snapshots ps
        WHERE ps.portfolio_id = p_portfolio_id
            AND ps.snapshot_date BETWEEN p_start_date AND p_end_date
        ORDER BY ps.snapshot_date
    ),
    calculated_returns AS (
        SELECT 
            snapshot_date,
            total_value_eur,
            CASE 
                WHEN prev_value IS NOT NULL AND prev_value > 0 
                THEN ((total_value_eur - prev_value) / prev_value) * 100
                ELSE 0
            END AS daily_return
        FROM daily_values
    )
    SELECT 
        cr.snapshot_date,
        cr.total_value_eur,
        cr.daily_return,
        -- Kumulative Return berechnen
        (
            SELECT 
                ((cr.total_value_eur - first_value.total_value_eur) / first_value.total_value_eur) * 100
            FROM (
                SELECT total_value_eur 
                FROM daily_values 
                WHERE prev_value IS NOT NULL 
                ORDER BY snapshot_date 
                LIMIT 1
            ) AS first_value
        ) AS cumulative_return
    FROM calculated_returns cr
    ORDER BY cr.snapshot_date;
END;
$$ LANGUAGE plpgsql;

-- ======================================================================================
-- QUERY FORMATTING
-- ======================================================================================

-- Einfache SELECT-Statements
SELECT 
    portfolio_id,
    portfolio_name,
    user_id,
    created_at
FROM portfolios 
WHERE user_id = '123e4567-e89b-12d3-a456-426614174000'
ORDER BY created_at DESC;

-- Komplexe Queries mit JOINs
SELECT 
    p.portfolio_id,
    p.portfolio_name,
    u.user_name,
    COUNT(pp.position_id) AS position_count,
    SUM(pp.quantity * md.current_price_eur) AS current_value_eur,
    SUM(pp.quantity * pp.average_price_eur) AS book_value_eur,
    (
        SUM(pp.quantity * md.current_price_eur) - 
        SUM(pp.quantity * pp.average_price_eur)
    ) AS unrealized_pnl_eur
FROM portfolios p
INNER JOIN users u ON p.user_id = u.user_id
LEFT JOIN portfolio_positions pp ON p.portfolio_id = pp.portfolio_id
LEFT JOIN market_data md ON pp.asset_symbol = md.symbol
    AND md.timestamp = (
        SELECT MAX(timestamp) 
        FROM market_data md2 
        WHERE md2.symbol = md.symbol
    )
WHERE p.created_at >= '2024-01-01'
    AND u.is_active = true
GROUP BY 
    p.portfolio_id,
    p.portfolio_name,
    u.user_name
HAVING COUNT(pp.position_id) > 0
ORDER BY 
    unrealized_pnl_eur DESC,
    p.portfolio_name ASC;

-- CTE (Common Table Expressions) für komplexe Logik
WITH portfolio_performance AS (
    SELECT 
        p.portfolio_id,
        p.portfolio_name,
        ps.snapshot_date,
        ps.total_value_eur,
        ps.total_value_eur - LAG(ps.total_value_eur) OVER (
            PARTITION BY p.portfolio_id 
            ORDER BY ps.snapshot_date
        ) AS daily_change_eur,
        CASE 
            WHEN LAG(ps.total_value_eur) OVER (
                PARTITION BY p.portfolio_id 
                ORDER BY ps.snapshot_date
            ) > 0
            THEN (
                (ps.total_value_eur - LAG(ps.total_value_eur) OVER (
                    PARTITION BY p.portfolio_id 
                    ORDER BY ps.snapshot_date
                )) / LAG(ps.total_value_eur) OVER (
                    PARTITION BY p.portfolio_id 
                    ORDER BY ps.snapshot_date
                )
            ) * 100
            ELSE 0
        END AS daily_return_percent
    FROM portfolios p
    INNER JOIN portfolio_snapshots ps ON p.portfolio_id = ps.portfolio_id
    WHERE ps.snapshot_date >= CURRENT_DATE - INTERVAL '30 days'
),
risk_metrics AS (
    SELECT 
        portfolio_id,
        portfolio_name,
        COUNT(*) AS data_points,
        AVG(daily_return_percent) AS avg_daily_return,
        STDDEV(daily_return_percent) AS volatility,
        MIN(daily_return_percent) AS worst_day,
        MAX(daily_return_percent) AS best_day
    FROM portfolio_performance
    WHERE daily_return_percent IS NOT NULL
    GROUP BY portfolio_id, portfolio_name
)
SELECT 
    rm.portfolio_id,
    rm.portfolio_name,
    rm.avg_daily_return,
    rm.volatility,
    rm.worst_day,
    rm.best_day,
    -- Sharpe Ratio (vereinfacht, ohne risikofreie Rate)
    CASE 
        WHEN rm.volatility > 0 
        THEN rm.avg_daily_return / rm.volatility
        ELSE 0
    END AS sharpe_ratio_simplified,
    rm.data_points
FROM risk_metrics rm
WHERE rm.data_points >= 10  -- Mindestens 10 Datenpunkte für valide Statistik
ORDER BY rm.avg_daily_return DESC;

-- ======================================================================================
-- UPDATE & DELETE PATTERNS
-- ======================================================================================

-- UPDATE mit sicheren WHERE-Klauseln
UPDATE portfolios 
SET 
    portfolio_name = 'Updated Portfolio Name',
    updated_at = NOW()
WHERE portfolio_id = '123e4567-e89b-12d3-a456-426614174000'
    AND user_id = '987fcdeb-51a2-43d1-9f12-345678901234';

-- Bulk UPDATE mit JOIN
UPDATE portfolio_positions 
SET 
    current_price_eur = md.price,
    updated_at = NOW()
FROM market_data md
WHERE portfolio_positions.asset_symbol = md.symbol
    AND md.timestamp = (
        SELECT MAX(timestamp) 
        FROM market_data md2 
        WHERE md2.symbol = md.symbol
    );

-- Sichere DELETE-Operationen
DELETE FROM portfolio_positions 
WHERE portfolio_id = '123e4567-e89b-12d3-a456-426614174000'
    AND quantity = 0;

-- Archivierung statt DELETE
UPDATE portfolios 
SET 
    is_deleted = true,
    deleted_at = NOW(),
    updated_at = NOW()
WHERE portfolio_id = '123e4567-e89b-12d3-a456-426614174000'
    AND user_id = '987fcdeb-51a2-43d1-9f12-345678901234';

-- ======================================================================================
-- TRANSACTION PATTERNS
-- ======================================================================================

-- Transaction für Portfolio-Update
BEGIN;

-- Portfolio-Informationen aktualisieren
UPDATE portfolios 
SET 
    portfolio_name = 'New Portfolio Name',
    updated_at = NOW()
WHERE portfolio_id = '123e4567-e89b-12d3-a456-426614174000';

-- Position hinzufügen/aktualisieren
INSERT INTO portfolio_positions (
    portfolio_id,
    asset_symbol,
    quantity,
    average_price_eur
) VALUES (
    '123e4567-e89b-12d3-a456-426614174000',
    'AAPL',
    100,
    150.25
)
ON CONFLICT (portfolio_id, asset_symbol) 
DO UPDATE SET 
    quantity = portfolio_positions.quantity + EXCLUDED.quantity,
    average_price_eur = (
        (portfolio_positions.quantity * portfolio_positions.average_price_eur) +
        (EXCLUDED.quantity * EXCLUDED.average_price_eur)
    ) / (portfolio_positions.quantity + EXCLUDED.quantity),
    updated_at = NOW();

-- Snapshot erstellen
INSERT INTO portfolio_snapshots (
    portfolio_id,
    snapshot_date,
    total_value_eur,
    position_count
)
SELECT 
    p.portfolio_id,
    CURRENT_DATE,
    COALESCE(SUM(pp.quantity * pp.average_price_eur), 0),
    COUNT(pp.position_id)
FROM portfolios p
LEFT JOIN portfolio_positions pp ON p.portfolio_id = pp.portfolio_id
WHERE p.portfolio_id = '123e4567-e89b-12d3-a456-426614174000'
GROUP BY p.portfolio_id;

COMMIT;

-- ======================================================================================
-- PERFORMANCE OPTIMIZATION PATTERNS
-- ======================================================================================

-- Optimierte Query für große Datenmengen
EXPLAIN (ANALYZE, BUFFERS) 
SELECT 
    p.portfolio_id,
    p.portfolio_name,
    latest_snapshot.total_value_eur,
    latest_snapshot.snapshot_date
FROM portfolios p
INNER JOIN LATERAL (
    SELECT 
        ps.total_value_eur,
        ps.snapshot_date
    FROM portfolio_snapshots ps
    WHERE ps.portfolio_id = p.portfolio_id
    ORDER BY ps.snapshot_date DESC
    LIMIT 1
) AS latest_snapshot ON true
WHERE p.user_id = '987fcdeb-51a2-43d1-9f12-345678901234'
ORDER BY latest_snapshot.total_value_eur DESC;

-- Index-optimierte Abfrage
SELECT 
    asset_symbol,
    COUNT(*) AS portfolio_count,
    SUM(quantity) AS total_quantity,
    AVG(average_price_eur) AS avg_price
FROM portfolio_positions 
WHERE created_at >= '2024-01-01'
    AND quantity > 0
GROUP BY asset_symbol
HAVING COUNT(*) >= 5  -- Mindestens in 5 Portfolios enthalten
ORDER BY portfolio_count DESC, total_quantity DESC;

-- ======================================================================================
-- DATA VALIDATION & CONSTRAINTS
-- ======================================================================================

-- Constraints für Datenintegrität
ALTER TABLE portfolio_positions 
ADD CONSTRAINT chk_portfolio_positions_quantity_positive 
CHECK (quantity > 0);

ALTER TABLE portfolio_positions 
ADD CONSTRAINT chk_portfolio_positions_price_positive 
CHECK (average_price_eur > 0);

ALTER TABLE portfolio_snapshots 
ADD CONSTRAINT chk_portfolio_snapshots_value_non_negative 
CHECK (total_value_eur >= 0);

-- Trigger für automatische Timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_portfolios_updated_at
    BEFORE UPDATE ON portfolios
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_portfolio_positions_updated_at
    BEFORE UPDATE ON portfolio_positions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ======================================================================================
-- COMMENTING & DOCUMENTATION
-- ======================================================================================

-- Tabellen-Kommentare
COMMENT ON TABLE portfolios IS 
'Benutzer-Portfolios mit grundlegenden Informationen und Metadaten';

COMMENT ON COLUMN portfolios.portfolio_id IS 
'Eindeutige UUID für das Portfolio';

COMMENT ON COLUMN portfolios.user_id IS 
'Referenz auf den Benutzer, dem das Portfolio gehört';

COMMENT ON COLUMN portfolios.portfolio_name IS 
'Benutzer-definierter Name für das Portfolio (max. 255 Zeichen)';

-- Index-Kommentare
COMMENT ON INDEX idx_portfolios_user_id IS 
'Performance-Index für Abfragen nach Benutzer-ID';

-- Funktions-Kommentare
COMMENT ON FUNCTION calculate_portfolio_performance(UUID, DATE, DATE) IS 
'Berechnet die tägliche und kumulative Performance eines Portfolios für einen gegebenen Zeitraum';
```

---

## 🔍 **2. CODE-REVIEW-GUIDELINES & QUALITY-GATES**

### 2.1 Code Review Checkliste

```markdown
# Code Review Checkliste - Aktienanalyse-Ökosystem

## 📋 **Allgemeine Code Quality**

### Funktionalität
- [ ] **Code erfüllt Anforderungen**: Implementierung entspricht den funktionalen Anforderungen
- [ ] **Edge Cases abgedeckt**: Grenzfälle und Fehlerszenarien berücksichtigt
- [ ] **Performance-Impact**: Keine negativen Auswirkungen auf System-Performance
- [ ] **Breaking Changes**: Rückwärtskompatibilität gewährleistet oder dokumentiert

### Code-Struktur & Design
- [ ] **Lesbarkeit**: Code ist verständlich und gut strukturiert
- [ ] **DRY Prinzip**: Keine unnötige Code-Duplikation
- [ ] **SOLID Prinzipien**: Single Responsibility, Open/Closed, etc. befolgt
- [ ] **Naming Conventions**: Konsistente und aussagekräftige Namen
- [ ] **Funktionsgröße**: Funktionen/Methoden haben angemessene Größe (<50 Zeilen)
- [ ] **Komplexität**: Zyklomatische Komplexität ist akzeptabel (<10)

### Dokumentation
- [ ] **Docstrings/Comments**: Öffentliche APIs sind dokumentiert
- [ ] **Inline Comments**: Komplexe Logik ist erklärt
- [ ] **README Updates**: Relevante Dokumentation aktualisiert
- [ ] **API Documentation**: OpenAPI/Swagger Specs aktualisiert

## 🐍 **Python-spezifische Checks**

### Style & Conventions
- [ ] **PEP 8 Compliance**: Code folgt PEP 8 Standards
- [ ] **Type Hints**: Alle öffentlichen Funktionen haben Type Hints
- [ ] **Import Organization**: Imports sind korrekt sortiert und gruppiert
- [ ] **String Formatting**: f-strings für String-Formatierung verwendet

### Error Handling
- [ ] **Exception Handling**: Angemessene try/except Blöcke
- [ ] **Custom Exceptions**: Spezifische Exception-Typen verwendet
- [ ] **Logging**: Angemessenes Logging für Errors und wichtige Events
- [ ] **Resource Management**: Context Manager für Ressourcen verwendet

### Async/Await
- [ ] **Async Patterns**: Korrekte Verwendung von async/await
- [ ] **Concurrency Safety**: Thread-Safe Code wo erforderlich
- [ ] **Resource Cleanup**: Async Ressourcen werden korrekt geschlossen

## ⚛️ **Frontend-spezifische Checks**

### React/TypeScript
- [ ] **Component Design**: Komponenten sind wiederverwendbar und testbar
- [ ] **Hook Usage**: React Hooks korrekt verwendet
- [ ] **State Management**: State-Updates sind korrekt implementiert
- [ ] **TypeScript**: Strenge Typisierung ohne `any` types
- [ ] **Performance**: useMemo/useCallback bei teuren Operationen

### Accessibility
- [ ] **ARIA Labels**: Screenreader-Unterstützung implementiert
- [ ] **Keyboard Navigation**: Tastatur-Navigation funktioniert
- [ ] **Color Contrast**: Ausreichender Farbkontrast
- [ ] **Focus Management**: Focus-Handling ist korrekt

### Performance
- [ ] **Bundle Size**: Keine unnötigen Dependencies
- [ ] **Lazy Loading**: Code-Splitting für große Komponenten
- [ ] **Image Optimization**: Bilder sind optimiert

## 🗄️ **Database-spezifische Checks**

### SQL Queries
- [ ] **Query Performance**: Queries sind optimiert und verwenden Indexes
- [ ] **SQL Injection**: Parametrisierte Queries verwendet
- [ ] **Transaction Safety**: ACID-Eigenschaften berücksichtigt
- [ ] **Migration Safety**: Database Migrations sind sicher

### Schema Design
- [ ] **Normalization**: Angemessene Datenbankstruktur
- [ ] **Constraints**: Foreign Keys und Check Constraints definiert
- [ ] **Indexing**: Notwendige Indexes vorhanden

## 🧪 **Testing**

### Test Coverage
- [ ] **Unit Tests**: Neue Funktionen haben Unit Tests (min. 80% Coverage)
- [ ] **Integration Tests**: API-Endpoints haben Integration Tests
- [ ] **Test Quality**: Tests sind aussagekräftig und nicht brüchig
- [ ] **Test Data**: Tests verwenden realistische aber anonymisierte Daten

### Test Patterns
- [ ] **Mocking**: External Dependencies sind gemockt
- [ ] **Test Isolation**: Tests sind unabhängig voneinander
- [ ] **Error Testing**: Fehlerszenarien werden getestet

## 🔒 **Security**

### Data Protection
- [ ] **Input Validation**: Alle Inputs werden validiert
- [ ] **Output Encoding**: Outputs werden korrekt encoded
- [ ] **Authentication**: Authentifizierung ist korrekt implementiert
- [ ] **Authorization**: Autorisierung prüft korrekte Berechtigung

### Secrets Management
- [ ] **No Hardcoded Secrets**: Keine Passwörter/API Keys im Code
- [ ] **Environment Variables**: Sensible Daten über ENV-Vars
- [ ] **Encryption**: Sensible Daten sind verschlüsselt

### Business Logic Security
- [ ] **Financial Calculations**: Geldbeträge sind korrekt validiert
- [ ] **Trading Limits**: Risk-Management-Regeln sind implementiert
- [ ] **Data Integrity**: Kritische Daten haben Integritätschecks

## 🚀 **Performance & Monitoring**

### Performance
- [ ] **Algorithmic Complexity**: O(n) Komplexität ist akzeptabel
- [ ] **Memory Usage**: Keine Memory Leaks
- [ ] **Caching**: Appropriate Caching-Strategien verwendet
- [ ] **Database Performance**: Queries sind optimiert

### Monitoring
- [ ] **Logging**: Angemessenes Logging für Monitoring
- [ ] **Metrics**: Performance-relevante Metriken werden gesammelt
- [ ] **Alerts**: Kritische Fehler triggern Alerts
- [ ] **Tracing**: Distributed Tracing für komplexe Flows

## 📦 **Dependencies & Configuration**

### Dependencies
- [ ] **Security Updates**: Dependencies sind aktuell
- [ ] **License Compatibility**: Lizenz-Kompatibilität geprüft
- [ ] **Minimal Dependencies**: Nur notwendige Dependencies hinzugefügt

### Configuration
- [ ] **Environment Configuration**: Konfiguration ist umgebungsspezifisch
- [ ] **Default Values**: Sinnvolle Default-Werte definiert
- [ ] **Configuration Validation**: Config wird validiert

## 🔄 **Git & Workflow**

### Commit Quality
- [ ] **Commit Messages**: Beschreibende Commit-Messages
- [ ] **Atomic Commits**: Ein Commit = Ein logischer Change
- [ ] **Branch Naming**: Branch folgt Naming-Konventionen
- [ ] **No Merge Conflicts**: Merge-Konflikte sind aufgelöst

### Code Organization
- [ ] **File Organization**: Dateien sind logisch organisiert
- [ ] **Import Cleanup**: Ungenutzte Imports entfernt
- [ ] **Dead Code**: Nicht genutzter Code entfernt

## ✅ **Review Completion**

### Reviewer Actions
- [ ] **Code verstanden**: Reviewer versteht die Implementierung
- [ ] **Tests ausgeführt**: Tests laufen erfolgreich
- [ ] **Manual Testing**: Manuelle Tests durchgeführt (falls erforderlich)
- [ ] **Documentation Review**: Dokumentation ist korrekt und vollständig

### Approval Criteria
- [ ] **Alle Checks bestanden**: Alle relevanten Punkte sind erfüllt
- [ ] **Feedback addressiert**: Reviewer-Feedback wurde umgesetzt
- [ ] **CI/CD Passed**: Alle automatisierten Tests bestanden
- [ ] **Deployment Ready**: Code ist bereit für Deployment

---

## 📊 **Review-Kategorien & Prioritäten**

### 🔴 **BLOCKING (Must Fix)**
- Security Vulnerabilities
- Breaking Changes ohne Migration
- Test Failures
- Performance Regressions
- Data Integrity Issues

### 🟡 **HIGH PRIORITY (Should Fix)**
- Code Quality Issues
- Missing Tests
- Documentation Gaps
- Style Guide Violations
- Minor Performance Issues

### 🟢 **LOW PRIORITY (Nice to Have)**
- Code Style Preferences
- Minor Refactoring Opportunities
- Additional Test Cases
- Documentation Improvements

---

## 🎯 **Review-Outcome Actions**

### ✅ **APPROVE**
- Alle Blocking Issues sind behoben
- Code-Qualität ist akzeptabel
- Tests sind vorhanden und bestehen
- Dokumentation ist ausreichend

### 🔄 **REQUEST CHANGES**
- Blocking Issues vorhanden
- Major Quality/Security Concerns
- Missing Critical Tests
- Incomplete Implementation

### 💬 **COMMENT**
- Minor Issues oder Suggestions
- Questions für Clarification
- Positive Feedback
- Learning Opportunities

---

## 📚 **Reviewer Guidelines**

### Konstruktives Feedback
- Erkläre das "Warum" bei Suggestions
- Biete konkrete Lösungsvorschläge
- Anerkenne gute Implementations
- Stelle Fragen für besseres Verständnis

### Timing & Communication
- Review binnen 24h für kritische Changes
- Review binnen 48h für Standard Changes
- Kommuniziere Delays proaktiv
- Nutze empathische Sprache

### Knowledge Sharing
- Teile relevante Ressourcen/Links
- Erkläre Best Practices
- Mentoring für Junior Developers
- Cross-team Learning fördern
```

### 2.2 Automated Quality Gates

```yaml
# /opt/aktienanalyse-ökosystem/.github/workflows/quality-gates.yml
# GitHub Actions Workflow für automatisierte Quality Gates

name: Quality Gates

on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [main, develop]

env:
  PYTHON_VERSION: "3.11"
  NODE_VERSION: "18"
  POSTGRES_VERSION: "15"

jobs:
  # ======================================================================================
  # PYTHON QUALITY GATES
  # ======================================================================================
  python-quality:
    name: Python Code Quality
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: test_password
          POSTGRES_DB: test_db
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
      
      redis:
        image: redis:7
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: ${{ env.PYTHON_VERSION }}

      - name: Cache Python Dependencies
        uses: actions/cache@v3
        with:
          path: ~/.cache/pip
          key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements*.txt') }}
          restore-keys: |
            ${{ runner.os }}-pip-

      - name: Install Dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt
          pip install -r requirements-dev.txt

      # Code Style & Linting
      - name: Run Black (Code Formatting)
        run: |
          black --check --diff .
        continue-on-error: false

      - name: Run isort (Import Sorting)
        run: |
          isort --check-only --diff .
        continue-on-error: false

      - name: Run flake8 (Linting)
        run: |
          flake8 . --config=.flake8
        continue-on-error: false

      - name: Run pylint (Advanced Linting)
        run: |
          pylint src/ --rcfile=.pylintrc --output-format=github
        continue-on-error: true

      # Type Checking
      - name: Run mypy (Type Checking)
        run: |
          mypy src/ --config-file=mypy.ini
        continue-on-error: false

      # Security Scanning
      - name: Run bandit (Security Scanning)
        run: |
          bandit -r src/ -f json -o bandit-report.json
          bandit -r src/ -f txt
        continue-on-error: false

      - name: Run safety (Dependency Security)
        run: |
          safety check --json --output safety-report.json
          safety check
        continue-on-error: false

      # Testing
      - name: Run pytest (Unit Tests)
        env:
          DATABASE_URL: postgresql://postgres:test_password@localhost/test_db
          REDIS_URL: redis://localhost:6379/0
        run: |
          pytest \
            --cov=src \
            --cov-report=xml \
            --cov-report=html \
            --cov-report=term \
            --cov-fail-under=80 \
            --junit-xml=pytest-report.xml \
            tests/

      - name: Upload Coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage.xml
          flags: python
          name: python-coverage

      # Code Metrics
      - name: Generate Code Metrics
        run: |
          radon cc src/ --average --show-complexity
          radon mi src/ --show
          xenon src/ --max-absolute B --max-modules A --max-average A

      # Documentation
      - name: Check Documentation
        run: |
          pydocstyle src/
          interrogate src/ --fail-under=80

      # Upload Artifacts
      - name: Upload Test Results
        uses: actions/upload-artifact@v3
        if: always()
        with:
          name: python-test-results
          path: |
            pytest-report.xml
            coverage.xml
            htmlcov/
            bandit-report.json
            safety-report.json

  # ======================================================================================
  # FRONTEND QUALITY GATES
  # ======================================================================================
  frontend-quality:
    name: Frontend Code Quality
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json

      - name: Install Dependencies
        working-directory: frontend
        run: npm ci

      # Code Style & Linting
      - name: Run ESLint
        working-directory: frontend
        run: |
          npm run lint -- --format=checkstyle --output-file=eslint-report.xml
          npm run lint
        continue-on-error: false

      - name: Run Prettier (Code Formatting)
        working-directory: frontend
        run: |
          npm run format:check
        continue-on-error: false

      # Type Checking
      - name: Run TypeScript Compiler
        working-directory: frontend
        run: |
          npm run type-check
        continue-on-error: false

      # Testing
      - name: Run Unit Tests
        working-directory: frontend
        run: |
          npm run test:coverage -- --watchAll=false --coverage --coverageReporters=lcov --coverageReporters=text
        env:
          CI: true

      - name: Run E2E Tests
        working-directory: frontend
        run: |
          npm run e2e:ci
        env:
          CI: true

      # Security Scanning
      - name: Run npm audit
        working-directory: frontend
        run: |
          npm audit --audit-level=moderate

      # Bundle Analysis
      - name: Analyze Bundle Size
        working-directory: frontend
        run: |
          npm run build
          npm run analyze:bundle

      # Accessibility Testing
      - name: Run Accessibility Tests
        working-directory: frontend
        run: |
          npm run test:a11y

      # Upload Coverage
      - name: Upload Coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          file: ./frontend/coverage/lcov.info
          flags: frontend
          name: frontend-coverage

      # Upload Artifacts
      - name: Upload Test Results
        uses: actions/upload-artifact@v3
        if: always()
        with:
          name: frontend-test-results
          path: |
            frontend/eslint-report.xml
            frontend/coverage/
            frontend/test-results/
            frontend/dist/

  # ======================================================================================
  # DATABASE QUALITY GATES
  # ======================================================================================
  database-quality:
    name: Database Quality
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: test_password
          POSTGRES_DB: test_db
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Install PostgreSQL Client
        run: |
          sudo apt-get update
          sudo apt-get install -y postgresql-client

      # Migration Testing
      - name: Test Database Migrations
        env:
          DATABASE_URL: postgresql://postgres:test_password@localhost/test_db
        run: |
          # Run migrations
          python scripts/run_migrations.py
          
          # Verify schema
          psql $DATABASE_URL -c "\dt" # List tables
          psql $DATABASE_URL -c "\di" # List indexes

      # SQL Linting
      - name: Run SQLFluff (SQL Linting)
        run: |
          pip install sqlfluff
          sqlfluff lint database/migrations/ --dialect=postgres
          sqlfluff lint database/functions/ --dialect=postgres

      # Performance Testing
      - name: Run Database Performance Tests
        env:
          DATABASE_URL: postgresql://postgres:test_password@localhost/test_db
        run: |
          python tests/database/test_performance.py

  # ======================================================================================
  # INTEGRATION QUALITY GATES
  # ======================================================================================
  integration-quality:
    name: Integration Tests
    runs-on: ubuntu-latest
    needs: [python-quality, frontend-quality, database-quality]
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: test_password
          POSTGRES_DB: test_db
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
      
      redis:
        image: redis:7
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: ${{ env.PYTHON_VERSION }}

      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}

      - name: Install Dependencies
        run: |
          pip install -r requirements.txt
          cd frontend && npm ci

      # API Integration Tests
      - name: Run API Integration Tests
        env:
          DATABASE_URL: postgresql://postgres:test_password@localhost/test_db
          REDIS_URL: redis://localhost:6379/0
        run: |
          pytest tests/integration/ -v --tb=short

      # End-to-End Tests
      - name: Start Services
        env:
          DATABASE_URL: postgresql://postgres:test_password@localhost/test_db
          REDIS_URL: redis://localhost:6379/0
        run: |
          # Start backend services
          python scripts/start_services.py &
          
          # Build and start frontend
          cd frontend
          npm run build
          npm run serve &
          
          # Wait for services to be ready
          sleep 30

      - name: Run E2E Tests
        run: |
          cd frontend
          npm run e2e:integration

  # ======================================================================================
  # SECURITY QUALITY GATES
  # ======================================================================================
  security-quality:
    name: Security Scanning
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      # SAST (Static Application Security Testing)
      - name: Run CodeQL Analysis
        uses: github/codeql-action/init@v2
        with:
          languages: python, javascript

      - name: Perform CodeQL Analysis
        uses: github/codeql-action/analyze@v2

      # Dependency Scanning
      - name: Run Snyk Security Scan
        uses: snyk/actions/python@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --severity-threshold=high

      # Container Scanning (if applicable)
      - name: Run Trivy Container Scan
        if: contains(github.event.head_commit.modified, 'Dockerfile')
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'aktienanalyse:latest'
          format: 'sarif'
          output: 'trivy-results.sarif'

      - name: Upload Trivy Results
        if: contains(github.event.head_commit.modified, 'Dockerfile')
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'

  # ======================================================================================
  # QUALITY GATE SUMMARY
  # ======================================================================================
  quality-gate-summary:
    name: Quality Gate Summary
    runs-on: ubuntu-latest
    needs: [python-quality, frontend-quality, database-quality, integration-quality, security-quality]
    if: always()
    
    steps:
      - name: Check Quality Gate Status
        run: |
          echo "Quality Gate Results:"
          echo "Python Quality: ${{ needs.python-quality.result }}"
          echo "Frontend Quality: ${{ needs.frontend-quality.result }}"
          echo "Database Quality: ${{ needs.database-quality.result }}"
          echo "Integration Quality: ${{ needs.integration-quality.result }}"
          echo "Security Quality: ${{ needs.security-quality.result }}"
          
          # Fail if any critical quality gate failed
          if [[ "${{ needs.python-quality.result }}" == "failure" || 
                "${{ needs.frontend-quality.result }}" == "failure" || 
                "${{ needs.database-quality.result }}" == "failure" || 
                "${{ needs.integration-quality.result }}" == "failure" || 
                "${{ needs.security-quality.result }}" == "failure" ]]; then
            echo "❌ Quality Gates Failed"
            exit 1
          else
            echo "✅ All Quality Gates Passed"
          fi

      - name: Generate Quality Report
        if: always()
        run: |
          cat > quality-report.md << 'EOF'
          # Quality Gate Report
          
          | Category | Status | Details |
          |----------|--------|---------|
          | Python | ${{ needs.python-quality.result }} | Code style, testing, security |
          | Frontend | ${{ needs.frontend-quality.result }} | TypeScript, React, accessibility |
          | Database | ${{ needs.database-quality.result }} | Migrations, performance |
          | Integration | ${{ needs.integration-quality.result }} | API, E2E testing |
          | Security | ${{ needs.security-quality.result }} | SAST, dependencies |
          
          **Overall Status: ${{ (needs.python-quality.result == 'success' && needs.frontend-quality.result == 'success' && needs.database-quality.result == 'success' && needs.integration-quality.result == 'success' && needs.security-quality.result == 'success') && '✅ PASSED' || '❌ FAILED' }}**
          EOF

      - name: Upload Quality Report
        uses: actions/upload-artifact@v3
        if: always()
        with:
          name: quality-gate-report
          path: quality-report.md
```

---

## 🌿 **3. GIT-WORKFLOW & BRANCH-STRATEGY**

### 3.1 Branch Strategy

```mermaid
gitGraph
    commit id: "Initial"
    branch develop
    checkout develop
    commit id: "Setup"
    
    branch feature/portfolio-service
    checkout feature/portfolio-service
    commit id: "Add portfolio model"
    commit id: "Implement CRUD operations"
    commit id: "Add unit tests"
    
    checkout develop
    merge feature/portfolio-service
    commit id: "Merge portfolio service"
    
    branch feature/trading-engine
    checkout feature/trading-engine
    commit id: "Trading engine core"
    commit id: "Risk management"
    
    checkout develop
    branch release/v1.0.0
    checkout release/v1.0.0
    commit id: "Prepare v1.0.0"
    commit id: "Version bump"
    
    checkout main
    merge release/v1.0.0
    commit id: "Release v1.0.0"
    
    checkout develop
    merge release/v1.0.0
    
    branch hotfix/critical-bug
    checkout hotfix/critical-bug
    commit id: "Fix critical issue"
    
    checkout main
    merge hotfix/critical-bug
    commit id: "Hotfix v1.0.1"
    
    checkout develop
    merge hotfix/critical-bug
```

### 3.2 Git Workflow Guidelines

```bash
#!/bin/bash
# /opt/aktienanalyse-ökosystem/scripts/git_workflow_guide.sh
# Git Workflow Automation für Aktienanalyse-Ökosystem

# ======================================================================================
# BRANCH NAMING CONVENTIONS
# ======================================================================================

# Feature Branches: feature/beschreibung-mit-bindestrichen
# - feature/portfolio-performance-calculation
# - feature/trading-order-validation
# - feature/user-authentication

# Bug Fix Branches: bugfix/issue-nummer-beschreibung
# - bugfix/123-portfolio-calculation-error
# - bugfix/456-trading-api-timeout

# Hotfix Branches: hotfix/kritische-beschreibung
# - hotfix/security-vulnerability
# - hotfix/data-corruption-fix

# Release Branches: release/version-nummer
# - release/v1.0.0
# - release/v1.1.0

# ======================================================================================
# FEATURE DEVELOPMENT WORKFLOW
# ======================================================================================

# Neues Feature starten
start_feature() {
    local feature_name="$1"
    
    if [[ -z "$feature_name" ]]; then
        echo "Usage: start_feature <feature-name>"
        echo "Example: start_feature portfolio-performance-calculation"
        return 1
    fi
    
    echo "🚀 Starting feature: $feature_name"
    
    # Auf develop Branch wechseln und aktualisieren
    git checkout develop
    git pull origin develop
    
    # Feature Branch erstellen
    git checkout -b "feature/$feature_name"
    
    # Initial commit für Feature Branch
    git commit --allow-empty -m "feat: initialize $feature_name feature

    - Created feature branch for $feature_name
    - Ready for development
    
    🤖 Generated with [Claude Code](https://claude.ai/code)
    
    Co-Authored-By: Claude <noreply@anthropic.com>"
    
    # Branch zu Remote pushen
    git push -u origin "feature/$feature_name"
    
    echo "✅ Feature branch 'feature/$feature_name' created and pushed"
    echo "📝 Next steps:"
    echo "   1. Implement the feature"
    echo "   2. Add tests"
    echo "   3. Update documentation"
    echo "   4. Create pull request"
}

# Feature entwickeln und committen
commit_feature() {
    local commit_message="$1"
    local commit_type="$2"
    
    if [[ -z "$commit_message" ]]; then
        echo "Usage: commit_feature <message> [type]"
        echo "Types: feat, fix, docs, style, refactor, test, chore"
        return 1
    fi
    
    if [[ -z "$commit_type" ]]; then
        commit_type="feat"
    fi
    
    # Validierung dass wir auf Feature Branch sind
    current_branch=$(git branch --show-current)
    if [[ ! "$current_branch" =~ ^feature/ ]]; then
        echo "❌ Error: Not on a feature branch (current: $current_branch)"
        return 1
    fi
    
    # Pre-commit Checks
    echo "🔍 Running pre-commit checks..."
    
    # Code Formatting
    if command -v black &> /dev/null; then
        black . --check || {
            echo "⚠️  Code formatting issues found. Running black..."
            black .
        }
    fi
    
    # Linting
    if command -v flake8 &> /dev/null; then
        flake8 . || {
            echo "❌ Linting errors found. Please fix before committing."
            return 1
        }
    fi
    
    # Tests
    if [[ -f "requirements-test.txt" ]] || [[ -f "pytest.ini" ]]; then
        echo "🧪 Running tests..."
        python -m pytest tests/ -x || {
            echo "❌ Tests failed. Please fix before committing."
            return 1
        }
    fi
    
    # Stage changes
    git add .
    
    # Create commit with conventional format
    git commit -m "$commit_type: $commit_message

    🤖 Generated with [Claude Code](https://claude.ai/code)
    
    Co-Authored-By: Claude <noreply@anthropic.com>"
    
    echo "✅ Commit created successfully"
    echo "💡 Remember to push regularly: git push"
}

# Feature abschließen und PR vorbereiten
finish_feature() {
    local feature_name
    
    # Aktuellen Branch ermitteln
    current_branch=$(git branch --show-current)
    if [[ ! "$current_branch" =~ ^feature/ ]]; then
        echo "❌ Error: Not on a feature branch (current: $current_branch)"
        return 1
    fi
    
    feature_name=${current_branch#feature/}
    
    echo "🏁 Finishing feature: $feature_name"
    
    # Final checks
    echo "🔍 Running final quality checks..."
    
    # Ensure all changes are committed
    if [[ -n $(git status --porcelain) ]]; then
        echo "❌ Error: Uncommitted changes found. Please commit all changes first."
        git status
        return 1
    fi
    
    # Update from develop
    git fetch origin
    git rebase origin/develop || {
        echo "❌ Error: Rebase conflicts. Please resolve manually."
        return 1
    }
    
    # Final test run
    if [[ -f "requirements-test.txt" ]] || [[ -f "pytest.ini" ]]; then
        echo "🧪 Running final test suite..."
        python -m pytest tests/ || {
            echo "❌ Final tests failed. Please fix before creating PR."
            return 1
        }
    fi
    
    # Push to remote
    git push --force-with-lease
    
    echo "✅ Feature '$feature_name' is ready for pull request"
    echo "📋 PR Checklist:"
    echo "   ✅ All tests passing"
    echo "   ✅ Code is rebased on latest develop"
    echo "   ✅ Feature is complete"
    echo "   📝 Create PR: https://github.com/your-org/aktienanalyse-ökosystem/compare/develop...$current_branch"
}

# ======================================================================================
# RELEASE WORKFLOW
# ======================================================================================

# Release Branch erstellen
start_release() {
    local version="$1"
    
    if [[ -z "$version" ]]; then
        echo "Usage: start_release <version>"
        echo "Example: start_release v1.0.0"
        return 1
    fi
    
    echo "🚀 Starting release: $version"
    
    # Auf develop wechseln und aktualisieren
    git checkout develop
    git pull origin develop
    
    # Release Branch erstellen
    git checkout -b "release/$version"
    
    # Version in Dateien aktualisieren
    if [[ -f "setup.py" ]]; then
        sed -i "s/version=\".*\"/version=\"${version#v}\"/" setup.py
    fi
    
    if [[ -f "package.json" ]]; then
        npm version --no-git-tag-version "${version#v}"
    fi
    
    if [[ -f "pyproject.toml" ]]; then
        sed -i "s/version = \".*\"/version = \"${version#v}\"/" pyproject.toml
    fi
    
    # Changelog aktualisieren
    if [[ -f "CHANGELOG.md" ]]; then
        update_changelog "$version"
    fi
    
    # Version commit
    git add .
    git commit -m "chore: prepare release $version

    - Bump version to $version
    - Update changelog
    - Prepare for release
    
    🤖 Generated with [Claude Code](https://claude.ai/code)
    
    Co-Authored-By: Claude <noreply@anthropic.com>"
    
    # Push release branch
    git push -u origin "release/$version"
    
    echo "✅ Release branch 'release/$version' created"
    echo "📝 Next steps:"
    echo "   1. Final testing and bug fixes"
    echo "   2. Update documentation"
    echo "   3. Create release PR to main"
}

# Release abschließen
finish_release() {
    local version
    
    # Aktuellen Branch ermitteln
    current_branch=$(git branch --show-current)
    if [[ ! "$current_branch" =~ ^release/ ]]; then
        echo "❌ Error: Not on a release branch (current: $current_branch)"
        return 1
    fi
    
    version=${current_branch#release/}
    
    echo "🏁 Finishing release: $version"
    
    # Final checks
    echo "🔍 Running release quality checks..."
    
    # Full test suite
    if [[ -f "requirements-test.txt" ]] || [[ -f "pytest.ini" ]]; then
        echo "🧪 Running full test suite..."
        python -m pytest tests/ --cov=src --cov-fail-under=80 || {
            echo "❌ Release tests failed or coverage too low."
            return 1
        }
    fi
    
    # Build checks
    if [[ -f "setup.py" ]]; then
        python setup.py check || {
            echo "❌ Setup.py check failed."
            return 1
        }
    fi
    
    # Security checks
    if command -v safety &> /dev/null; then
        safety check || {
            echo "❌ Security vulnerabilities found."
            return 1
        }
    fi
    
    # Merge to main
    git checkout main
    git pull origin main
    git merge --no-ff "release/$version" -m "chore: release $version

    - Merge release branch $version
    - Version $version ready for production
    
    🤖 Generated with [Claude Code](https://claude.ai/code)
    
    Co-Authored-By: Claude <noreply@anthropic.com>"
    
    # Create and push tag
    git tag -a "$version" -m "Release $version

    Features and improvements in this release.
    See CHANGELOG.md for detailed information.
    
    🤖 Generated with [Claude Code](https://claude.ai/code)
    
    Co-Authored-By: Claude <noreply@anthropic.com>"
    
    git push origin main
    git push origin "$version"
    
    # Merge back to develop
    git checkout develop
    git merge --no-ff "release/$version" -m "chore: merge release $version back to develop
    
    🤖 Generated with [Claude Code](https://claude.ai/code)
    
    Co-Authored-By: Claude <noreply@anthropic.com>"
    
    git push origin develop
    
    # Cleanup release branch
    git branch -d "release/$version"
    git push origin --delete "release/$version"
    
    echo "✅ Release $version completed successfully"
    echo "🎉 Release is now live on main branch with tag $version"
}

# ======================================================================================
# HOTFIX WORKFLOW
# ======================================================================================

# Hotfix starten
start_hotfix() {
    local hotfix_name="$1"
    local version="$2"
    
    if [[ -z "$hotfix_name" ]] || [[ -z "$version" ]]; then
        echo "Usage: start_hotfix <hotfix-name> <version>"
        echo "Example: start_hotfix security-vulnerability v1.0.1"
        return 1
    fi
    
    echo "🚨 Starting hotfix: $hotfix_name (version: $version)"
    
    # Von main Branch abzweigen
    git checkout main
    git pull origin main
    
    # Hotfix Branch erstellen
    git checkout -b "hotfix/$hotfix_name"
    
    # Initial commit
    git commit --allow-empty -m "hotfix: initialize $hotfix_name hotfix

    - Created hotfix branch for $hotfix_name
    - Target version: $version
    
    🤖 Generated with [Claude Code](https://claude.ai/code)
    
    Co-Authored-By: Claude <noreply@anthropic.com>"
    
    git push -u origin "hotfix/$hotfix_name"
    
    echo "✅ Hotfix branch 'hotfix/$hotfix_name' created"
    echo "⚠️  Remember: Hotfixes should be minimal and focused!"
}

# Hotfix abschließen
finish_hotfix() {
    local hotfix_name
    local version="$1"
    
    # Aktuellen Branch ermitteln
    current_branch=$(git branch --show-current)
    if [[ ! "$current_branch" =~ ^hotfix/ ]]; then
        echo "❌ Error: Not on a hotfix branch (current: $current_branch)"
        return 1
    fi
    
    hotfix_name=${current_branch#hotfix/}
    
    if [[ -z "$version" ]]; then
        echo "Usage: finish_hotfix <version>"
        echo "Example: finish_hotfix v1.0.1"
        return 1
    fi
    
    echo "🏁 Finishing hotfix: $hotfix_name (version: $version)"
    
    # Version bump
    if [[ -f "setup.py" ]]; then
        sed -i "s/version=\".*\"/version=\"${version#v}\"/" setup.py
    fi
    
    # Hotfix tests
    if [[ -f "requirements-test.txt" ]] || [[ -f "pytest.ini" ]]; then
        echo "🧪 Running hotfix tests..."
        python -m pytest tests/ -k "not slow" || {
            echo "❌ Hotfix tests failed."
            return 1
        }
    fi
    
    # Commit version bump
    git add .
    git commit -m "chore: bump version to $version for hotfix

    🤖 Generated with [Claude Code](https://claude.ai/code)
    
    Co-Authored-By: Claude <noreply@anthropic.com>"
    
    # Merge to main
    git checkout main
    git pull origin main
    git merge --no-ff "hotfix/$hotfix_name" -m "hotfix: $hotfix_name ($version)

    Critical hotfix for production deployment.
    
    🤖 Generated with [Claude Code](https://claude.ai/code)
    
    Co-Authored-By: Claude <noreply@anthropic.com>"
    
    # Create and push tag
    git tag -a "$version" -m "Hotfix $version

    Critical fix: $hotfix_name
    
    🤖 Generated with [Claude Code](https://claude.ai/code)
    
    Co-Authored-By: Claude <noreply@anthropic.com>"
    
    git push origin main
    git push origin "$version"
    
    # Merge back to develop
    git checkout develop
    git pull origin develop
    git merge --no-ff "hotfix/$hotfix_name" -m "hotfix: merge $hotfix_name to develop
    
    🤖 Generated with [Claude Code](https://claude.ai/code)
    
    Co-Authored-By: Claude <noreply@anthropic.com>"
    
    git push origin develop
    
    # Cleanup hotfix branch
    git branch -d "hotfix/$hotfix_name"
    git push origin --delete "hotfix/$hotfix_name"
    
    echo "✅ Hotfix $hotfix_name completed successfully"
    echo "🚀 Hotfix $version is now live"
}

# ======================================================================================
# UTILITY FUNCTIONS
# ======================================================================================

# Changelog automatisch aktualisieren
update_changelog() {
    local version="$1"
    local changelog_file="CHANGELOG.md"
    
    if [[ ! -f "$changelog_file" ]]; then
        create_initial_changelog "$version"
        return
    fi
    
    # Neue Version am Anfang des Changelog einfügen
    local temp_file=$(mktemp)
    local current_date=$(date +%Y-%m-%d)
    
    # Header erstellen
    echo "# Changelog" > "$temp_file"
    echo "" >> "$temp_file"
    echo "Alle wichtigen Änderungen an diesem Projekt werden in dieser Datei dokumentiert." >> "$temp_file"
    echo "" >> "$temp_file"
    
    # Neue Version hinzufügen
    echo "## [$version] - $current_date" >> "$temp_file"
    echo "" >> "$temp_file"
    echo "### Added" >> "$temp_file"
    echo "- TODO: Neue Features beschreiben" >> "$temp_file"
    echo "" >> "$temp_file"
    echo "### Changed" >> "$temp_file"
    echo "- TODO: Änderungen beschreiben" >> "$temp_file"
    echo "" >> "$temp_file"
    echo "### Fixed" >> "$temp_file"
    echo "- TODO: Bugfixes beschreiben" >> "$temp_file"
    echo "" >> "$temp_file"
    
    # Alten Inhalt anhängen (ohne Header)
    tail -n +4 "$changelog_file" >> "$temp_file"
    
    # Temporäre Datei über Original kopieren
    mv "$temp_file" "$changelog_file"
    
    echo "📝 $changelog_file updated with $version"
    echo "⚠️  Please edit the changelog to add actual changes!"
}

# Initial Changelog erstellen
create_initial_changelog() {
    local version="$1"
    local current_date=$(date +%Y-%m-%d)
    
    cat > CHANGELOG.md << EOF
# Changelog

Alle wichtigen Änderungen an diesem Projekt werden in dieser Datei dokumentiert.

Das Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.0.0/),
und dieses Projekt folgt [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [$version] - $current_date

### Added
- Initiale Version des Aktienanalyse-Ökosystems
- Portfolio-Management-Funktionalität
- Trading-Engine Integration
- Event-Driven Architecture
- Monitoring und Observability

### Security
- Sichere Authentifizierung implementiert
- Input-Validierung für alle API-Endpoints
- Verschlüsselung für sensible Daten
EOF

    echo "📝 Initial CHANGELOG.md created"
}

# Status des aktuellen Branches anzeigen
branch_status() {
    local current_branch=$(git branch --show-current)
    local branch_type=""
    
    if [[ "$current_branch" =~ ^feature/ ]]; then
        branch_type="Feature"
    elif [[ "$current_branch" =~ ^release/ ]]; then
        branch_type="Release"
    elif [[ "$current_branch" =~ ^hotfix/ ]]; then
        branch_type="Hotfix"
    elif [[ "$current_branch" == "main" ]]; then
        branch_type="Main"
    elif [[ "$current_branch" == "develop" ]]; then
        branch_type="Develop"
    else
        branch_type="Unknown"
    fi
    
    echo "📍 Current Branch: $current_branch ($branch_type)"
    echo ""
    
    # Git status
    git status --short
    
    echo ""
    echo "📊 Branch Information:"
    
    # Commits ahead/behind
    if [[ "$current_branch" != "main" ]]; then
        local ahead_behind=$(git rev-list --left-right --count main...$current_branch)
        local behind=$(echo $ahead_behind | cut -d$'\t' -f1)
        local ahead=$(echo $ahead_behind | cut -d$'\t' -f2)
        
        if [[ "$ahead" -gt 0 ]]; then
            echo "   📈 $ahead commits ahead of main"
        fi
        
        if [[ "$behind" -gt 0 ]]; then
            echo "   📉 $behind commits behind main"
        fi
    fi
    
    # Last commit
    echo "   📝 Last commit: $(git log -1 --pretty=format:'%h - %s (%cr)')"
    
    echo ""
    echo "🔧 Available Actions:"
    case $branch_type in
        "Feature")
            echo "   💾 commit_feature \"message\" [type]"
            echo "   🏁 finish_feature"
            ;;
        "Release")
            echo "   🏁 finish_release"
            ;;
        "Hotfix")
            echo "   🏁 finish_hotfix <version>"
            ;;
        "Develop")
            echo "   🚀 start_feature <name>"
            echo "   📦 start_release <version>"
            ;;
        "Main")
            echo "   🚨 start_hotfix <name> <version>"
            ;;
    esac
}

# Help function
git_workflow_help() {
    echo "🌿 Git Workflow Commands für Aktienanalyse-Ökosystem"
    echo ""
    echo "📋 Feature Development:"
    echo "   start_feature <name>              - Neues Feature starten"
    echo "   commit_feature <message> [type]   - Feature commit mit Checks"
    echo "   finish_feature                    - Feature für PR vorbereiten"
    echo ""
    echo "📦 Release Management:"
    echo "   start_release <version>           - Release Branch starten"
    echo "   finish_release                    - Release abschließen"
    echo ""
    echo "🚨 Hotfix Workflow:"
    echo "   start_hotfix <name> <version>     - Kritischen Hotfix starten"
    echo "   finish_hotfix <version>           - Hotfix abschließen"
    echo ""
    echo "ℹ️  Information:"
    echo "   branch_status                     - Aktuellen Branch-Status anzeigen"
    echo "   git_workflow_help                 - Diese Hilfe anzeigen"
    echo ""
    echo "📚 Branch Naming:"
    echo "   feature/beschreibung-mit-bindestrichen"
    echo "   bugfix/issue-nummer-beschreibung"
    echo "   hotfix/kritische-beschreibung"
    echo "   release/v1.0.0"
    echo ""
    echo "📝 Commit Types: feat, fix, docs, style, refactor, test, chore"
}

# Aliases für einfachere Nutzung
alias gws='branch_status'
alias gwh='git_workflow_help'
alias gwsf='start_feature'
alias gwcf='commit_feature'
alias gwff='finish_feature'
alias gwsr='start_release'
alias gwfr='finish_release'
alias gwsh='start_hotfix'
alias gwfh='finish_hotfix'

# Wenn das Skript direkt ausgeführt wird
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-help}" in
        "start_feature"|"sf")
            start_feature "$2"
            ;;
        "commit_feature"|"cf")
            commit_feature "$2" "$3"
            ;;
        "finish_feature"|"ff")
            finish_feature
            ;;
        "start_release"|"sr")
            start_release "$2"
            ;;
        "finish_release"|"fr")
            finish_release
            ;;
        "start_hotfix"|"sh")
            start_hotfix "$2" "$3"
            ;;
        "finish_hotfix"|"fh")
            finish_hotfix "$2"
            ;;
        "status"|"s")
            branch_status
            ;;
        "help"|"h"|*)
            git_workflow_help
            ;;
    esac
fi
```

### 3.3 Commit Message Guidelines

```bash
# /opt/aktienanalyse-ökosystem/docs/git_commit_guidelines.md

# Commit Message Format

## Conventional Commits Standard

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types
- **feat**: Neue Feature-Implementierung
- **fix**: Bug Fix
- **docs**: Nur Dokumentations-Änderungen
- **style**: Code-Style-Änderungen (Formatierung, Leerzeichen, etc.)
- **refactor**: Code-Änderungen ohne neue Features oder Bug-Fixes
- **perf**: Performance-Verbesserungen
- **test**: Hinzufügen oder Korrigieren von Tests
- **chore**: Wartungsarbeiten (Build-Prozess, Dependencies, etc.)
- **ci**: CI/CD-Konfiguration Änderungen
- **build**: Build-System oder externe Dependencies Änderungen

### Scopes (Optional)
- **portfolio**: Portfolio-Management
- **trading**: Trading-Engine
- **auth**: Authentifizierung
- **api**: API-Änderungen
- **ui**: Frontend/UI
- **db**: Database
- **config**: Konfiguration
- **docs**: Dokumentation

### Beispiele

```bash
# Feature
feat(portfolio): add portfolio performance calculation

Implemented comprehensive portfolio performance metrics including:
- Daily, monthly, and yearly returns
- Sharpe ratio calculation
- Maximum drawdown analysis
- Benchmark comparison functionality

Closes #123

# Bug Fix
fix(trading): resolve order validation error for fractional shares

Fixed validation logic that was rejecting valid fractional share orders.
The validator now correctly handles decimal quantities >= 0.001.

Fixes #456

# Documentation
docs(api): update trading endpoints documentation

- Added examples for order placement
- Updated response schemas
- Added error code documentation

# Refactoring
refactor(auth): simplify JWT token validation

Extracted token validation into reusable utility function.
No functional changes, improved code maintainability.

# Performance
perf(db): optimize portfolio queries with new indexes

Added composite indexes on portfolio_snapshots table:
- (portfolio_id, snapshot_date)
- (user_id, snapshot_date)

Query performance improved by ~70% for dashboard loads.

# Chore
chore: update dependencies to latest versions

- Updated Flask to 2.3.2
- Updated SQLAlchemy to 2.0.18
- Fixed security vulnerabilities in requests library

# CI/CD
ci: add automated security scanning to pipeline

Integrated SAST tools:
- Added Bandit for Python security scanning
- Added npm audit for frontend dependencies
- Configured security gate in quality checks
```

### Breaking Changes

```bash
# Breaking Change mit BREAKING CHANGE footer
feat(api): change portfolio API response format

BREAKING CHANGE: Portfolio API now returns paginated results.

Before:
{
  "portfolios": [...]
}

After:
{
  "data": [...],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100
  }
}

Migration guide: Update frontend to handle new pagination structure.
```

### Co-authored Commits

```bash
# Für Pair Programming
feat(trading): implement order routing logic

Co-authored-by: Jane Doe <jane@example.com>
```

---

## 🛠️ **4. LOCAL-DEVELOPMENT-SETUP AUTOMATISIERUNG**

### 4.1 Development Environment Setup

```bash
#!/bin/bash
# /opt/aktienanalyse-ökosystem/scripts/setup_dev_environment.sh
# Automatisiertes Setup für lokale Entwicklungsumgebung

set -euo pipefail

# ======================================================================================
# CONFIGURATION
# ======================================================================================

PROJECT_NAME="aktienanalyse-ökosystem"
PYTHON_VERSION="3.11"
NODE_VERSION="18"
POSTGRES_VERSION="15"
REDIS_VERSION="7"

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ======================================================================================
# SYSTEM DETECTION
# ======================================================================================

detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            echo "ubuntu"
        elif command -v yum &> /dev/null; then
            echo "centos"
        elif command -v pacman &> /dev/null; then
            echo "arch"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

OS=$(detect_os)
log_info "Detected OS: $OS"

# ======================================================================================
# DEPENDENCY INSTALLATION
# ======================================================================================

install_system_dependencies() {
    log_info "Installing system dependencies..."
    
    case $OS in
        "ubuntu")
            sudo apt-get update
            sudo apt-get install -y \
                curl \
                wget \
                git \
                build-essential \
                software-properties-common \
                apt-transport-https \
                ca-certificates \
                gnupg \
                lsb-release \
                postgresql-client \
                redis-tools \
                jq \
                unzip
            ;;
        "macos")
            if ! command -v brew &> /dev/null; then
                log_info "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            
            brew update
            brew install \
                curl \
                wget \
                git \
                postgresql \
                redis \
                jq \
                coreutils
            ;;
        "centos")
            sudo yum update -y
            sudo yum install -y \
                curl \
                wget \
                git \
                gcc \
                gcc-c++ \
                make \
                postgresql \
                redis \
                jq \
                unzip
            ;;
        *)
            log_warning "Unsupported OS. Please install dependencies manually."
            ;;
    esac
    
    log_success "System dependencies installed"
}

# Python Installation mit pyenv
install_python() {
    log_info "Setting up Python $PYTHON_VERSION..."
    
    # pyenv installieren falls nicht vorhanden
    if ! command -v pyenv &> /dev/null; then
        log_info "Installing pyenv..."
        curl https://pyenv.run | bash
        
        # pyenv zu PATH hinzufügen
        export PATH="$HOME/.pyenv/bin:$PATH"
        eval "$(pyenv init --path)"
        eval "$(pyenv init -)"
        
        # Shell-Konfiguration aktualisieren
        if [[ -f "$HOME/.bashrc" ]]; then
            echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> ~/.bashrc
            echo 'eval "$(pyenv init --path)"' >> ~/.bashrc
            echo 'eval "$(pyenv init -)"' >> ~/.bashrc
        fi
        
        if [[ -f "$HOME/.zshrc" ]]; then
            echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> ~/.zshrc
            echo 'eval "$(pyenv init --path)"' >> ~/.zshrc
            echo 'eval "$(pyenv init -)"' >> ~/.zshrc
        fi
    fi
    
    # Python Version installieren
    if ! pyenv versions | grep -q "$PYTHON_VERSION"; then
        log_info "Installing Python $PYTHON_VERSION..."
        pyenv install "$PYTHON_VERSION"
    fi
    
    # Lokale Python Version setzen
    pyenv local "$PYTHON_VERSION"
    
    log_success "Python $PYTHON_VERSION configured"
}

# Node.js Installation mit nvm
install_nodejs() {
    log_info "Setting up Node.js $NODE_VERSION..."
    
    # nvm installieren falls nicht vorhanden
    if ! command -v nvm &> /dev/null; then
        log_info "Installing nvm..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
        
        # nvm laden
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    fi
    
    # Node.js Version installieren und verwenden
    nvm install "$NODE_VERSION"
    nvm use "$NODE_VERSION"
    nvm alias default "$NODE_VERSION"
    
    # npm auf latest aktualisieren
    npm install -g npm@latest
    
    log_success "Node.js $NODE_VERSION configured"
}

# PostgreSQL Setup
setup_postgresql() {
    log_info "Setting up PostgreSQL..."
    
    case $OS in
        "ubuntu")
            # PostgreSQL installieren
            sudo apt-get install -y postgresql postgresql-contrib
            
            # Service starten
            sudo systemctl start postgresql
            sudo systemctl enable postgresql
            ;;
        "macos")
            # PostgreSQL mit Homebrew
            brew install postgresql@$POSTGRES_VERSION
            brew services start postgresql@$POSTGRES_VERSION
            ;;
        "centos")
            sudo yum install -y postgresql-server postgresql-contrib
            sudo postgresql-setup initdb
            sudo systemctl start postgresql
            sudo systemctl enable postgresql
            ;;
    esac
    
    # Development Database erstellen
    if command -v psql &> /dev/null; then
        log_info "Creating development database..."
        
        # User und Database für Development
        sudo -u postgres psql -c "CREATE USER aktienanalyse_dev WITH PASSWORD 'dev_password';" || true
        sudo -u postgres psql -c "CREATE DATABASE aktienanalyse_dev OWNER aktienanalyse_dev;" || true
        sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE aktienanalyse_dev TO aktienanalyse_dev;" || true
        
        # Test Database
        sudo -u postgres psql -c "CREATE DATABASE aktienanalyse_test OWNER aktienanalyse_dev;" || true
        sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE aktienanalyse_test TO aktienanalyse_dev;" || true
        
        log_success "PostgreSQL databases created"
    else
        log_warning "PostgreSQL not accessible. Please create databases manually."
    fi
}

# Redis Setup
setup_redis() {
    log_info "Setting up Redis..."
    
    case $OS in
        "ubuntu")
            sudo apt-get install -y redis-server
            sudo systemctl start redis-server
            sudo systemctl enable redis-server
            ;;
        "macos")
            brew install redis
            brew services start redis
            ;;
        "centos")
            sudo yum install -y redis
            sudo systemctl start redis
            sudo systemctl enable redis
            ;;
    esac
    
    # Redis Konfiguration für Development
    if command -v redis-cli &> /dev/null; then
        # Test Redis Connection
        redis-cli ping > /dev/null && log_success "Redis is running" || log_warning "Redis connection failed"
    fi
}

# ======================================================================================
# PROJECT SETUP
# ======================================================================================

setup_project_structure() {
    log_info "Setting up project structure..."
    
    # Virtuelle Umgebung erstellen
    if [[ ! -d "venv" ]]; then
        python -m venv venv
        log_success "Python virtual environment created"
    fi
    
    # Virtual Environment aktivieren
    source venv/bin/activate
    
    # Python Dependencies installieren
    if [[ -f "requirements.txt" ]]; then
        log_info "Installing Python dependencies..."
        pip install --upgrade pip
        pip install -r requirements.txt
        
        if [[ -f "requirements-dev.txt" ]]; then
            pip install -r requirements-dev.txt
        fi
        
        log_success "Python dependencies installed"
    fi
    
    # Frontend Dependencies installieren
    if [[ -f "frontend/package.json" ]]; then
        log_info "Installing frontend dependencies..."
        cd frontend
        npm install
        cd ..
        log_success "Frontend dependencies installed"
    fi
    
    # Pre-commit Hooks setup
    if command -v pre-commit &> /dev/null; then
        log_info "Setting up pre-commit hooks..."
        pre-commit install
        log_success "Pre-commit hooks installed"
    fi
}

setup_environment_files() {
    log_info "Setting up environment configuration..."
    
    # .env Datei erstellen falls nicht vorhanden
    if [[ ! -f ".env" ]]; then
        cat > .env << 'EOF'
# Development Environment Configuration
DEBUG=True
ENVIRONMENT=development

# Database Configuration
DATABASE_URL=postgresql://aktienanalyse_dev:dev_password@localhost/aktienanalyse_dev
TEST_DATABASE_URL=postgresql://aktienanalyse_dev:dev_password@localhost/aktienanalyse_test

# Redis Configuration
REDIS_URL=redis://localhost:6379/0

# Secret Keys (Development Only - Change for Production!)
SECRET_KEY=dev-secret-key-change-in-production
JWT_SECRET=dev-jwt-secret-change-in-production

# API Configuration
API_HOST=localhost
API_PORT=8000
FRONTEND_URL=http://localhost:3000

# External APIs (Add your own keys)
BITPANDA_API_KEY=your-bitpanda-api-key
BITPANDA_API_SECRET=your-bitpanda-api-secret

# Logging
LOG_LEVEL=DEBUG
LOG_FILE=logs/development.log

# Monitoring
ZABBIX_SERVER=10.1.1.103
ZABBIX_PORT=10051

# Email (Development)
MAIL_SERVER=localhost
MAIL_PORT=1025
MAIL_USERNAME=
MAIL_PASSWORD=
MAIL_USE_TLS=False
EOF
        
        log_success "Environment file created"
        log_warning "Please update .env with your actual API keys and settings"
    fi
    
    # .env.test Datei für Tests
    if [[ ! -f ".env.test" ]]; then
        cat > .env.test << 'EOF'
# Test Environment Configuration
DEBUG=False
ENVIRONMENT=test

# Test Database
DATABASE_URL=postgresql://aktienanalyse_dev:dev_password@localhost/aktienanalyse_test
REDIS_URL=redis://localhost:6379/1

# Test Secrets
SECRET_KEY=test-secret-key
JWT_SECRET=test-jwt-secret

# Disable external APIs in tests
BITPANDA_API_KEY=test-key
BITPANDA_API_SECRET=test-secret

# Test Logging
LOG_LEVEL=WARNING
EOF
        
        log_success "Test environment file created"
    fi
}

setup_database_schema() {
    log_info "Setting up database schema..."
    
    # Virtual Environment aktivieren
    source venv/bin/activate
    
    # Database Migrations ausführen
    if [[ -f "scripts/run_migrations.py" ]]; then
        python scripts/run_migrations.py
        log_success "Database migrations completed"
    else
        log_warning "Migration script not found. Please run migrations manually."
    fi
    
    # Test Data laden (optional)
    if [[ -f "scripts/load_test_data.py" ]]; then
        read -p "Load test data? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            python scripts/load_test_data.py
            log_success "Test data loaded"
        fi
    fi
}

# ======================================================================================
# DEVELOPMENT TOOLS SETUP
# ======================================================================================

setup_development_tools() {
    log_info "Setting up development tools..."
    
    # Git Hooks
    if [[ ! -f ".git/hooks/pre-commit" ]]; then
        cp scripts/git-hooks/pre-commit .git/hooks/
        chmod +x .git/hooks/pre-commit
        log_success "Git pre-commit hook installed"
    fi
    
    # IDE Configuration
    setup_vscode_config
    
    # Development Scripts ausführbar machen
    chmod +x scripts/*.sh
    chmod +x scripts/git_workflow_guide.sh
    
    log_success "Development tools configured"
}

setup_vscode_config() {
    if [[ ! -d ".vscode" ]]; then
        mkdir -p .vscode
        
        # settings.json
        cat > .vscode/settings.json << 'EOF'
{
    "python.defaultInterpreterPath": "./venv/bin/python",
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": true,
    "python.linting.flake8Enabled": true,
    "python.formatting.provider": "black",
    "python.testing.pytestEnabled": true,
    "python.testing.pytestArgs": ["tests/"],
    "typescript.preferences.quoteStyle": "single",
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
        "source.organizeImports": true
    },
    "files.exclude": {
        "**/__pycache__": true,
        "**/.pytest_cache": true,
        "**/node_modules": true,
        "**/dist": true,
        "**/.coverage": true,
        "**/htmlcov": true
    }
}
EOF
        
        # launch.json für Debugging
        cat > .vscode/launch.json << 'EOF'
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Python: Debug API Server",
            "type": "python",
            "request": "launch",
            "program": "src/main.py",
            "env": {
                "ENVIRONMENT": "development"
            },
            "console": "integratedTerminal",
            "cwd": "${workspaceFolder}"
        },
        {
            "name": "Python: Debug Tests",
            "type": "python",
            "request": "launch",
            "module": "pytest",
            "args": ["tests/", "-v"],
            "console": "integratedTerminal",
            "cwd": "${workspaceFolder}"
        }
    ]
}
EOF
        
        # extensions.json
        cat > .vscode/extensions.json << 'EOF'
{
    "recommendations": [
        "ms-python.python",
        "ms-python.flake8",
        "ms-python.pylint",
        "ms-python.black-formatter",
        "bradlc.vscode-tailwindcss",
        "esbenp.prettier-vscode",
        "dbaeumer.vscode-eslint",
        "ms-vscode.vscode-typescript-next",
        "GitLab.gitlab-workflow",
        "ms-vscode.vscode-json",
        "redhat.vscode-yaml",
        "ms-vsliveshare.vsliveshare"
    ]
}
EOF
        
        log_success "VS Code configuration created"
    fi
}

# ======================================================================================
# VERIFICATION & TESTING
# ======================================================================================

verify_installation() {
    log_info "Verifying installation..."
    
    local errors=0
    
    # Python check
    if source venv/bin/activate && python --version | grep -q "$PYTHON_VERSION"; then
        log_success "Python $PYTHON_VERSION: OK"
    else
        log_error "Python installation failed"
        ((errors++))
    fi
    
    # Node.js check
    if node --version | grep -q "v$NODE_VERSION"; then
        log_success "Node.js $NODE_VERSION: OK"
    else
        log_error "Node.js installation failed"
        ((errors++))
    fi
    
    # PostgreSQL check
    if psql -h localhost -U aktienanalyse_dev -d aktienanalyse_dev -c "SELECT 1;" &> /dev/null; then
        log_success "PostgreSQL: OK"
    else
        log_error "PostgreSQL connection failed"
        ((errors++))
    fi
    
    # Redis check
    if redis-cli ping | grep -q "PONG"; then
        log_success "Redis: OK"
    else
        log_error "Redis connection failed"
        ((errors++))
    fi
    
    # Dependencies check
    if source venv/bin/activate && python -c "import flask, sqlalchemy, redis" &> /dev/null; then
        log_success "Python dependencies: OK"
    else
        log_error "Python dependencies missing"
        ((errors++))
    fi
    
    if [[ -f "frontend/package.json" ]] && cd frontend && npm list react &> /dev/null; then
        log_success "Frontend dependencies: OK"
        cd ..
    else
        log_error "Frontend dependencies missing"
        ((errors++))
    fi
    
    # Environment files check
    if [[ -f ".env" ]] && [[ -f ".env.test" ]]; then
        log_success "Environment configuration: OK"
    else
        log_error "Environment files missing"
        ((errors++))
    fi
    
    return $errors
}

run_initial_tests() {
    log_info "Running initial tests..."
    
    # Virtual Environment aktivieren
    source venv/bin/activate
    
    # Unit Tests
    if [[ -f "pytest.ini" ]] || [[ -f "pyproject.toml" ]]; then
        log_info "Running Python unit tests..."
        if python -m pytest tests/ -x --tb=short; then
            log_success "Unit tests: PASSED"
        else
            log_warning "Some unit tests failed"
        fi
    fi
    
    # Frontend Tests
    if [[ -f "frontend/package.json" ]]; then
        log_info "Running frontend tests..."
        cd frontend
        if npm test -- --watchAll=false; then
            log_success "Frontend tests: PASSED"
        else
            log_warning "Some frontend tests failed"
        fi
        cd ..
    fi
    
    # Linting
    log_info "Running code quality checks..."
    if flake8 src/ && black --check src/; then
        log_success "Code quality: PASSED"
    else
        log_warning "Code quality issues found"
    fi
}

# ======================================================================================
# MAIN INSTALLATION FLOW
# ======================================================================================

main() {
    echo "🚀 Setting up Aktienanalyse-Ökosystem Development Environment"
    echo "================================================================"
    echo ""
    
    # System requirements check
    if [[ "$OS" == "unknown" ]]; then
        log_error "Unsupported operating system"
        exit 1
    fi
    
    # Root check
    if [[ $EUID -eq 0 ]]; then
        log_error "Please don't run this script as root"
        exit 1
    fi
    
    # Steps
    install_system_dependencies
    install_python
    install_nodejs
    setup_postgresql
    setup_redis
    setup_project_structure
    setup_environment_files
    setup_database_schema
    setup_development_tools
    
    echo ""
    echo "🔍 Verifying installation..."
    if verify_installation; then
        log_success "Installation verification completed successfully"
        
        echo ""
        log_info "Running initial tests..."
        run_initial_tests
        
        echo ""
        echo "🎉 Development environment setup complete!"
        echo ""
        echo "📋 Next steps:"
        echo "   1. Update .env with your actual API keys"
        echo "   2. Review and customize configuration files"
        echo "   3. Start development: ./scripts/start_dev_server.sh"
        echo "   4. Open http://localhost:8000 for API"
        echo "   5. Open http://localhost:3000 for frontend"
        echo ""
        echo "📚 Useful commands:"
        echo "   source venv/bin/activate  # Activate Python environment"
        echo "   ./scripts/git_workflow_guide.sh help  # Git workflow help"
        echo "   pytest tests/  # Run tests"
        echo "   npm run dev  # Start frontend dev server"
        echo ""
        
    else
        log_error "Installation verification failed"
        echo ""
        echo "❌ Setup incomplete. Please check the errors above and:"
        echo "   1. Fix any missing dependencies"
        echo "   2. Check database and Redis connections"
        echo "   3. Verify environment configuration"
        echo "   4. Run this script again"
        exit 1
    fi
}

# Cleanup function
cleanup() {
    if [[ -f "/tmp/setup.lock" ]]; then
        rm -f /tmp/setup.lock
    fi
}

trap cleanup EXIT

# Lock file to prevent concurrent runs
if [[ -f "/tmp/setup.lock" ]]; then
    log_error "Setup script is already running"
    exit 1
fi

touch /tmp/setup.lock

# Run main function
main "$@"
```

### 4.2 Development Server Startup

```bash
#!/bin/bash
# /opt/aktienanalyse-ökosystem/scripts/start_dev_server.sh
# Development Server Startup Script

set -euo pipefail

# Farben
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Services starten
start_services() {
    log_info "Starting development services..."
    
    # Virtual Environment aktivieren
    if [[ -f "venv/bin/activate" ]]; then
        source venv/bin/activate
        log_success "Python virtual environment activated"
    else
        log_error "Virtual environment not found. Run setup first."
        exit 1
    fi
    
    # Environment laden
    if [[ -f ".env" ]]; then
        export $(grep -v '^#' .env | xargs)
        log_success "Environment variables loaded"
    fi
    
    # Database Check
    if ! psql "$DATABASE_URL" -c "SELECT 1;" &> /dev/null; then
        log_error "Database connection failed. Check PostgreSQL service."
        exit 1
    fi
    
    # Redis Check
    if ! redis-cli ping &> /dev/null; then
        log_error "Redis connection failed. Check Redis service."
        exit 1
    fi
    
    # Log Directory erstellen
    mkdir -p logs
    
    # Backend Services starten
    log_info "Starting backend services..."
    
    # API Server
    python src/main.py > logs/api_server.log 2>&1 &
    API_PID=$!
    echo $API_PID > logs/api_server.pid
    
    # Event Bus Service
    python src/services/events/main.py > logs/event_bus.log 2>&1 &
    EVENT_PID=$!
    echo $EVENT_PID > logs/event_bus.pid
    
    # Monitoring Service
    python src/services/monitoring/main.py > logs/monitoring.log 2>&1 &
    MONITOR_PID=$!
    echo $MONITOR_PID > logs/monitoring.pid
    
    sleep 5
    
    # Health Checks
    if curl -s http://localhost:8000/health > /dev/null; then
        log_success "API Server started (PID: $API_PID)"
    else
        log_error "API Server failed to start"
    fi
    
    # Frontend starten (falls vorhanden)
    if [[ -f "frontend/package.json" ]]; then
        log_info "Starting frontend development server..."
        cd frontend
        npm run dev > ../logs/frontend.log 2>&1 &
        FRONTEND_PID=$!
        echo $FRONTEND_PID > ../logs/frontend.pid
        cd ..
        
        sleep 10
        
        if curl -s http://localhost:3000 > /dev/null; then
            log_success "Frontend Server started (PID: $FRONTEND_PID)"
        else
            log_warning "Frontend Server may have issues"
        fi
    fi
    
    log_success "All services started successfully"
    
    echo ""
    echo "🌐 Services running:"
    echo "   API Server:     http://localhost:8000"
    echo "   API Docs:       http://localhost:8000/docs"
    echo "   Frontend:       http://localhost:3000"
    echo "   Monitoring:     http://localhost:8004"
    echo ""
    echo "📝 Logs:"
    echo "   API:            tail -f logs/api_server.log"
    echo "   Event Bus:      tail -f logs/event_bus.log"
    echo "   Monitoring:     tail -f logs/monitoring.log"
    echo "   Frontend:       tail -f logs/frontend.log"
    echo ""
    echo "🛑 Stop services: ./scripts/stop_dev_server.sh"
}

# Cleanup function
cleanup() {
    log_info "Cleaning up..."
    
    # PIDs lesen und Services stoppen
    for pid_file in logs/*.pid; do
        if [[ -f "$pid_file" ]]; then
            pid=$(cat "$pid_file")
            if kill -0 "$pid" 2>/dev/null; then
                kill "$pid"
                log_info "Stopped process $pid"
            fi
            rm -f "$pid_file"
        fi
    done
}

trap cleanup EXIT INT TERM

# Main
if [[ "${1:-}" == "stop" ]]; then
    cleanup
    exit 0
fi

start_services

# Keep script running
log_info "Press Ctrl+C to stop all services"
while true; do
    sleep 30
    
    # Health Check der Services
    if ! curl -s http://localhost:8000/health > /dev/null; then
        log_warning "API Server health check failed"
    fi
done
```

Die Development & Contribution Guidelines Spezifikation ist vollständig.
```