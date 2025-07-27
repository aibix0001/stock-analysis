# 📋 OpenAPI/Swagger-Spezifikationen - Alle 5 Services

## 🎯 **Übersicht**

**Kontext**: Vollständige API-Definitionen für alle 5 native LXC-Services
**Ziel**: OpenAPI 3.1-konforme Spezifikationen für Frontend-Integration und Service-Kommunikation  
**Ansatz**: Event-driven APIs mit REST-Endpoints für Client-Integration

---

## 🏗️ **1. SERVICE-API-ARCHITEKTUR**

### 1.1 **API-Design-Prinzipien**
```yaml
# OpenAPI Design Standards für Aktienanalyse-Ökosystem

design_principles:
  # Event-Driven REST-Hybrid
  - REST-Endpoints für Client-Requests
  - Event-Publication für Service-Communication
  - Standardized Error-Responses
  - Consistent Resource-Naming
  
  # API-Versioning
  - URL-Path-Versioning: /api/v1/
  - Backward-Compatibility für 1 Major-Version
  - Deprecation-Warnings in Headers
  
  # Response-Standards
  - JSON-Only (application/json)
  - Consistent Error-Format
  - Pagination für Collections
  - HATEOAS für Navigation

api_structure:
  base_url: "https://10.1.1.120"
  api_prefix: "/api/v1"
  services:
    - intelligent-core-service: ":8001/api/v1"
    - broker-gateway-service: ":8002/api/v1" 
    - event-bus-service: ":8003/api/v1"
    - monitoring-service: ":8004/api/v1"
    - frontend-service: ":8443" (UI + API-Proxy)
```

### 1.2 **Gemeinsame OpenAPI-Komponenten**
```yaml
# shared/openapi/common-components.yaml
openapi: 3.1.0
info:
  title: Aktienanalyse-Ökosystem Common Components
  version: 1.0.0

components:
  securitySchemes:
    SessionAuth:
      type: apiKey
      in: cookie
      name: aktienanalyse_session
      description: Session-based authentication via HTTP cookies
    
    ApiKeyAuth:
      type: apiKey
      in: header
      name: X-API-Key
      description: Service-to-service API key authentication

  schemas:
    # Standard Error Response
    Error:
      type: object
      required: [error, message, timestamp]
      properties:
        error:
          type: string
          description: Error code
          example: "INVALID_REQUEST"
        message:
          type: string
          description: Human-readable error message
          example: "The request is invalid"
        timestamp:
          type: string
          format: date-time
          description: Error timestamp
        details:
          type: object
          description: Additional error details
        trace_id:
          type: string
          description: Request trace ID for debugging
    
    # Pagination Response
    PaginationMeta:
      type: object
      properties:
        page:
          type: integer
          minimum: 1
          description: Current page number
        limit:
          type: integer
          minimum: 1
          maximum: 100
          description: Items per page
        total_items:
          type: integer
          minimum: 0
          description: Total number of items
        total_pages:
          type: integer
          minimum: 0
          description: Total number of pages
        has_next:
          type: boolean
          description: Whether there are more pages
        has_previous:
          type: boolean
          description: Whether there are previous pages
    
    # Standard List Response
    ListResponse:
      type: object
      properties:
        data:
          type: array
          description: List of items
        meta:
          $ref: '#/components/schemas/PaginationMeta'
    
    # Event Schema
    EventMessage:
      type: object
      required: [event_type, event_id, timestamp, data]
      properties:
        event_type:
          type: string
          description: Type of event
          example: "portfolio.updated"
        event_id:
          type: string
          format: uuid
          description: Unique event identifier
        timestamp:
          type: string
          format: date-time
          description: Event timestamp
        source_service:
          type: string
          description: Service that published the event
        correlation_id:
          type: string
          description: Request correlation ID
        data:
          type: object
          description: Event payload data

  responses:
    BadRequest:
      description: Bad Request
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            error: "BAD_REQUEST"
            message: "The request is malformed"
            timestamp: "2025-01-20T10:30:00Z"
    
    Unauthorized:
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            error: "UNAUTHORIZED"
            message: "Authentication required"
            timestamp: "2025-01-20T10:30:00Z"
    
    Forbidden:
      description: Forbidden
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            error: "FORBIDDEN"
            message: "Access denied"
            timestamp: "2025-01-20T10:30:00Z"
    
    NotFound:
      description: Not Found
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            error: "NOT_FOUND"
            message: "Resource not found"
            timestamp: "2025-01-20T10:30:00Z"
    
    InternalServerError:
      description: Internal Server Error
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            error: "INTERNAL_ERROR"
            message: "An internal error occurred"
            timestamp: "2025-01-20T10:30:00Z"

  parameters:
    PageParam:
      name: page
      in: query
      description: Page number
      required: false
      schema:
        type: integer
        minimum: 1
        default: 1
    
    LimitParam:
      name: limit
      in: query
      description: Items per page
      required: false
      schema:
        type: integer
        minimum: 1
        maximum: 100
        default: 20
    
    SortParam:
      name: sort
      in: query
      description: Sort field and direction
      required: false
      schema:
        type: string
        pattern: '^[a-zA-Z_][a-zA-Z0-9_]*(:asc|:desc)?$'
        example: "created_at:desc"
```

---

## 📊 **2. INTELLIGENT-CORE-SERVICE API**

### 2.1 **Core-Service OpenAPI-Spezifikation**
```yaml
# services/intelligent-core-service/openapi.yaml
openapi: 3.1.0
info:
  title: Intelligent Core Service API
  description: Central analysis engine and data aggregation service
  version: 1.0.0
  contact:
    name: Aktienanalyse-Ökosystem
    url: https://10.1.1.120
  license:
    name: Private Use Only

servers:
  - url: http://127.0.0.1:8001/api/v1
    description: Local development server
  - url: https://10.1.1.120/api/v1
    description: Production server (via NGINX proxy)

security:
  - SessionAuth: []
  - ApiKeyAuth: []

paths:
  # Portfolio Management
  /portfolio:
    get:
      summary: Get portfolio overview
      description: Returns complete portfolio with current positions and performance
      tags: [Portfolio]
      parameters:
        - $ref: '#/components/parameters/PageParam'
        - $ref: '#/components/parameters/LimitParam'
        - name: include_performance
          in: query
          description: Include performance metrics
          schema:
            type: boolean
            default: true
      responses:
        200:
          description: Portfolio data
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    $ref: '#/components/schemas/Portfolio'
                  performance:
                    $ref: '#/components/schemas/PortfolioPerformance'
        401:
          $ref: '#/components/responses/Unauthorized'
        500:
          $ref: '#/components/responses/InternalServerError'

  /portfolio/positions:
    get:
      summary: Get portfolio positions
      description: Returns all current portfolio positions
      tags: [Portfolio]
      parameters:
        - $ref: '#/components/parameters/PageParam'
        - $ref: '#/components/parameters/LimitParam'
        - name: active_only
          in: query
          description: Only return active positions
          schema:
            type: boolean
            default: true
      responses:
        200:
          description: Portfolio positions
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/ListResponse'
                  - type: object
                    properties:
                      data:
                        type: array
                        items:
                          $ref: '#/components/schemas/Position'

  /portfolio/positions/{symbol}:
    get:
      summary: Get specific position
      description: Returns detailed information for a specific position
      tags: [Portfolio]
      parameters:
        - name: symbol
          in: path
          required: true
          description: Stock symbol (e.g., AAPL, MSFT)
          schema:
            type: string
            pattern: '^[A-Z]{1,5}$'
      responses:
        200:
          description: Position details
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Position'
        404:
          $ref: '#/components/responses/NotFound'

  # Stock Analysis
  /analysis/stocks/{symbol}:
    get:
      summary: Get stock analysis
      description: Returns comprehensive analysis for a specific stock
      tags: [Analysis]
      parameters:
        - name: symbol
          in: path
          required: true
          description: Stock symbol
          schema:
            type: string
            pattern: '^[A-Z]{1,5}$'
        - name: timeframe
          in: query
          description: Analysis timeframe
          schema:
            type: string
            enum: [1d, 1w, 1m, 3m, 6m, 1y]
            default: 1m
      responses:
        200:
          description: Stock analysis data
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/StockAnalysis'

  /analysis/recommendations:
    get:
      summary: Get trading recommendations
      description: Returns AI-generated trading recommendations
      tags: [Analysis]
      parameters:
        - name: risk_level
          in: query
          description: Risk tolerance level
          schema:
            type: string
            enum: [conservative, moderate, aggressive]
            default: moderate
        - name: max_recommendations
          in: query
          description: Maximum number of recommendations
          schema:
            type: integer
            minimum: 1
            maximum: 20
            default: 10
      responses:
        200:
          description: Trading recommendations
          content:
            application/json:
              schema:
                type: object
                properties:
                  recommendations:
                    type: array
                    items:
                      $ref: '#/components/schemas/TradingRecommendation'
                  generated_at:
                    type: string
                    format: date-time

  # Market Data
  /market-data/quotes:
    get:
      summary: Get market quotes
      description: Returns current market quotes for specified symbols
      tags: [Market Data]
      parameters:
        - name: symbols
          in: query
          required: true
          description: Comma-separated list of symbols
          schema:
            type: string
            pattern: '^[A-Z]{1,5}(,[A-Z]{1,5})*$'
            example: "AAPL,MSFT,GOOGL"
      responses:
        200:
          description: Market quotes
          content:
            application/json:
              schema:
                type: object
                properties:
                  quotes:
                    type: array
                    items:
                      $ref: '#/components/schemas/MarketQuote'
                  timestamp:
                    type: string
                    format: date-time

components:
  schemas:
    Portfolio:
      type: object
      properties:
        total_value:
          type: number
          format: double
          description: Total portfolio value in EUR
        cash_balance:
          type: number
          format: double
          description: Available cash balance
        positions_count:
          type: integer
          description: Number of positions
        currency:
          type: string
          enum: [EUR, USD]
          default: EUR
        last_updated:
          type: string
          format: date-time

    PortfolioPerformance:
      type: object
      properties:
        daily_pnl:
          type: number
          format: double
          description: Daily profit/loss
        daily_pnl_percent:
          type: number
          format: double
          description: Daily P&L percentage
        total_return:
          type: number
          format: double
          description: Total return since inception
        total_return_percent:
          type: number
          format: double
          description: Total return percentage
        sharpe_ratio:
          type: number
          format: double
          description: Sharpe ratio
        max_drawdown:
          type: number
          format: double
          description: Maximum drawdown

    Position:
      type: object
      required: [symbol, quantity, market_value]
      properties:
        symbol:
          type: string
          description: Stock symbol
        company_name:
          type: string
          description: Company name
        quantity:
          type: number
          format: double
          description: Number of shares
        average_cost:
          type: number
          format: double
          description: Average cost per share
        market_price:
          type: number
          format: double
          description: Current market price
        market_value:
          type: number
          format: double
          description: Total market value
        unrealized_pnl:
          type: number
          format: double
          description: Unrealized profit/loss
        unrealized_pnl_percent:
          type: number
          format: double
          description: Unrealized P&L percentage
        currency:
          type: string
          enum: [EUR, USD]
        last_updated:
          type: string
          format: date-time

    StockAnalysis:
      type: object
      properties:
        symbol:
          type: string
        technical_indicators:
          type: object
          properties:
            rsi:
              type: number
              description: Relative Strength Index
            macd:
              type: object
              properties:
                value:
                  type: number
                signal:
                  type: number
                histogram:
                  type: number
            moving_averages:
              type: object
              properties:
                sma_20:
                  type: number
                sma_50:
                  type: number
                ema_12:
                  type: number
                ema_26:
                  type: number
        fundamental_data:
          type: object
          properties:
            market_cap:
              type: number
            pe_ratio:
              type: number
            eps:
              type: number
            dividend_yield:
              type: number
        sentiment_analysis:
          type: object
          properties:
            sentiment_score:
              type: number
              minimum: -1
              maximum: 1
            confidence:
              type: number
              minimum: 0
              maximum: 1

    TradingRecommendation:
      type: object
      properties:
        symbol:
          type: string
        action:
          type: string
          enum: [BUY, SELL, HOLD]
        confidence:
          type: number
          minimum: 0
          maximum: 1
        target_price:
          type: number
        stop_loss:
          type: number
        reasoning:
          type: string
        risk_rating:
          type: string
          enum: [LOW, MEDIUM, HIGH]
        time_horizon:
          type: string
          enum: [SHORT, MEDIUM, LONG]

    MarketQuote:
      type: object
      properties:
        symbol:
          type: string
        price:
          type: number
        change:
          type: number
        change_percent:
          type: number
        volume:
          type: integer
        bid:
          type: number
        ask:
          type: number
        timestamp:
          type: string
          format: date-time
```

---

## 💰 **3. BROKER-GATEWAY-SERVICE API**

### 3.1 **Broker-Gateway OpenAPI-Spezifikation**
```yaml
# services/broker-gateway-service/openapi.yaml
openapi: 3.1.0
info:
  title: Broker Gateway Service API
  description: Trading operations and broker integration service
  version: 1.0.0

servers:
  - url: http://127.0.0.1:8002/api/v1
    description: Local development server

security:
  - SessionAuth: []
  - ApiKeyAuth: []

paths:
  # Trading Orders
  /orders:
    get:
      summary: Get trading orders
      description: Returns list of trading orders with optional filtering
      tags: [Trading]
      parameters:
        - $ref: '#/components/parameters/PageParam'
        - $ref: '#/components/parameters/LimitParam'
        - name: status
          in: query
          description: Filter by order status
          schema:
            type: string
            enum: [pending, filled, cancelled, rejected]
        - name: symbol
          in: query
          description: Filter by symbol
          schema:
            type: string
        - name: from_date
          in: query
          description: Filter orders from date
          schema:
            type: string
            format: date
      responses:
        200:
          description: Trading orders
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/ListResponse'
                  - type: object
                    properties:
                      data:
                        type: array
                        items:
                          $ref: '#/components/schemas/TradingOrder'

    post:
      summary: Place trading order
      description: Places a new trading order
      tags: [Trading]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/OrderRequest'
      responses:
        201:
          description: Order placed successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/TradingOrder'
        400:
          $ref: '#/components/responses/BadRequest'
        401:
          $ref: '#/components/responses/Unauthorized'

  /orders/{order_id}:
    get:
      summary: Get order details
      description: Returns detailed information for a specific order
      tags: [Trading]
      parameters:
        - name: order_id
          in: path
          required: true
          description: Order ID
          schema:
            type: string
            format: uuid
      responses:
        200:
          description: Order details
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/TradingOrder'
        404:
          $ref: '#/components/responses/NotFound'

    delete:
      summary: Cancel order
      description: Cancels a pending order
      tags: [Trading]
      parameters:
        - name: order_id
          in: path
          required: true
          description: Order ID
          schema:
            type: string
            format: uuid
      responses:
        200:
          description: Order cancelled successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/TradingOrder'
        400:
          description: Order cannot be cancelled
        404:
          $ref: '#/components/responses/NotFound'

  # Account Information
  /account/balance:
    get:
      summary: Get account balance
      description: Returns current account balance and buying power
      tags: [Account]
      responses:
        200:
          description: Account balance
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/AccountBalance'

  /account/transactions:
    get:
      summary: Get transaction history
      description: Returns transaction history with optional filtering
      tags: [Account]
      parameters:
        - $ref: '#/components/parameters/PageParam'
        - $ref: '#/components/parameters/LimitParam'
        - name: transaction_type
          in: query
          description: Filter by transaction type
          schema:
            type: string
            enum: [buy, sell, dividend, fee, deposit, withdrawal]
        - name: from_date
          in: query
          schema:
            type: string
            format: date
        - name: to_date
          in: query
          schema:
            type: string
            format: date
      responses:
        200:
          description: Transaction history
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/ListResponse'
                  - type: object
                    properties:
                      data:
                        type: array
                        items:
                          $ref: '#/components/schemas/Transaction'

  # Broker Integration
  /broker/status:
    get:
      summary: Get broker connection status
      description: Returns current broker API connection status
      tags: [Broker]
      responses:
        200:
          description: Broker status
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/BrokerStatus'

components:
  schemas:
    TradingOrder:
      type: object
      required: [order_id, symbol, side, quantity, order_type, status]
      properties:
        order_id:
          type: string
          format: uuid
          description: Unique order identifier
        symbol:
          type: string
          description: Stock symbol
        side:
          type: string
          enum: [buy, sell]
          description: Order side
        quantity:
          type: number
          format: double
          minimum: 0
          description: Number of shares
        order_type:
          type: string
          enum: [market, limit, stop, stop_limit]
          description: Order type
        limit_price:
          type: number
          format: double
          description: Limit price (for limit orders)
        stop_price:
          type: number
          format: double
          description: Stop price (for stop orders)
        status:
          type: string
          enum: [pending, filled, cancelled, rejected, partially_filled]
          description: Order status
        filled_quantity:
          type: number
          format: double
          description: Quantity filled
        average_fill_price:
          type: number
          format: double
          description: Average fill price
        total_fees:
          type: number
          format: double
          description: Total trading fees
        created_at:
          type: string
          format: date-time
        updated_at:
          type: string
          format: date-time
        expires_at:
          type: string
          format: date-time
          description: Order expiration time

    OrderRequest:
      type: object
      required: [symbol, side, quantity, order_type]
      properties:
        symbol:
          type: string
          pattern: '^[A-Z]{1,5}$'
          description: Stock symbol
        side:
          type: string
          enum: [buy, sell]
        quantity:
          type: number
          format: double
          minimum: 0.001
        order_type:
          type: string
          enum: [market, limit, stop, stop_limit]
        limit_price:
          type: number
          format: double
          minimum: 0
        stop_price:
          type: number
          format: double
          minimum: 0
        time_in_force:
          type: string
          enum: [day, gtc, ioc, fok]
          default: day
          description: Time in force

    AccountBalance:
      type: object
      properties:
        cash_balance:
          type: number
          format: double
          description: Available cash balance
        buying_power:
          type: number
          format: double
          description: Total buying power
        portfolio_value:
          type: number
          format: double
          description: Total portfolio value
        margin_used:
          type: number
          format: double
          description: Margin currently used
        margin_available:
          type: number
          format: double
          description: Available margin
        currency:
          type: string
          enum: [EUR, USD]
        last_updated:
          type: string
          format: date-time

    Transaction:
      type: object
      properties:
        transaction_id:
          type: string
          format: uuid
        transaction_type:
          type: string
          enum: [buy, sell, dividend, fee, deposit, withdrawal]
        symbol:
          type: string
          description: Stock symbol (null for non-trading transactions)
        quantity:
          type: number
          format: double
          description: Number of shares (null for non-trading transactions)
        price:
          type: number
          format: double
          description: Price per share
        total_amount:
          type: number
          format: double
          description: Total transaction amount
        fees:
          type: number
          format: double
          description: Transaction fees
        currency:
          type: string
          enum: [EUR, USD]
        transaction_date:
          type: string
          format: date-time
        settlement_date:
          type: string
          format: date
        description:
          type: string
          description: Transaction description

    BrokerStatus:
      type: object
      properties:
        broker_name:
          type: string
          example: "Bitpanda Pro"
        connection_status:
          type: string
          enum: [connected, disconnected, error]
        last_heartbeat:
          type: string
          format: date-time
        api_rate_limit:
          type: object
          properties:
            requests_remaining:
              type: integer
            reset_time:
              type: string
              format: date-time
        market_status:
          type: string
          enum: [open, closed, pre_market, after_hours]
        supported_features:
          type: array
          items:
            type: string
          example: ["real_time_quotes", "order_placement", "portfolio_sync"]
```

---

## 🚌 **4. EVENT-BUS-SERVICE API**

### 4.1 **Event-Bus OpenAPI-Spezifikation**
```yaml
# services/event-bus-service/openapi.yaml
openapi: 3.1.0
info:
  title: Event Bus Service API
  description: Central event messaging and coordination service
  version: 1.0.0

servers:
  - url: http://127.0.0.1:8003/api/v1
    description: Local development server

security:
  - ApiKeyAuth: []

paths:
  # Event Publishing
  /events:
    post:
      summary: Publish event
      description: Publishes an event to the event bus
      tags: [Events]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/EventRequest'
      responses:
        202:
          description: Event accepted for processing
          content:
            application/json:
              schema:
                type: object
                properties:
                  event_id:
                    type: string
                    format: uuid
                  status:
                    type: string
                    enum: [accepted]
                  timestamp:
                    type: string
                    format: date-time

  /events/{event_id}:
    get:
      summary: Get event status
      description: Returns the processing status of a specific event
      tags: [Events]
      parameters:
        - name: event_id
          in: path
          required: true
          schema:
            type: string
            format: uuid
      responses:
        200:
          description: Event status
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/EventStatus'

  # Event Subscriptions
  /subscriptions:
    get:
      summary: List subscriptions
      description: Returns all active event subscriptions
      tags: [Subscriptions]
      responses:
        200:
          description: Event subscriptions
          content:
            application/json:
              schema:
                type: object
                properties:
                  subscriptions:
                    type: array
                    items:
                      $ref: '#/components/schemas/EventSubscription'

    post:
      summary: Create subscription
      description: Creates a new event subscription
      tags: [Subscriptions]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/SubscriptionRequest'
      responses:
        201:
          description: Subscription created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/EventSubscription'

  /subscriptions/{subscription_id}:
    delete:
      summary: Delete subscription
      description: Removes an event subscription
      tags: [Subscriptions]
      parameters:
        - name: subscription_id
          in: path
          required: true
          schema:
            type: string
            format: uuid
      responses:
        204:
          description: Subscription deleted

  # Event History and Monitoring
  /events/history:
    get:
      summary: Get event history
      description: Returns recent event history with optional filtering
      tags: [Events]
      parameters:
        - $ref: '#/components/parameters/PageParam'
        - $ref: '#/components/parameters/LimitParam'
        - name: event_type
          in: query
          description: Filter by event type
          schema:
            type: string
        - name: source_service
          in: query
          description: Filter by source service
          schema:
            type: string
        - name: from_timestamp
          in: query
          schema:
            type: string
            format: date-time
      responses:
        200:
          description: Event history
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/ListResponse'
                  - type: object
                    properties:
                      data:
                        type: array
                        items:
                          $ref: '#/components/schemas/EventHistoryItem'

  /health:
    get:
      summary: Event bus health
      description: Returns event bus health and statistics
      tags: [Health]
      responses:
        200:
          description: Event bus health
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/EventBusHealth'

components:
  schemas:
    EventRequest:
      type: object
      required: [event_type, data]
      properties:
        event_type:
          type: string
          pattern: '^[a-z_]+\\.[a-z_]+\\.[a-z_]+$'
          description: Event type in format domain.entity.action
          example: "portfolio.position.updated"
        data:
          type: object
          description: Event payload
        correlation_id:
          type: string
          description: Request correlation ID
        metadata:
          type: object
          description: Additional event metadata

    EventStatus:
      type: object
      properties:
        event_id:
          type: string
          format: uuid
        status:
          type: string
          enum: [accepted, processing, delivered, failed]
        created_at:
          type: string
          format: date-time
        processed_at:
          type: string
          format: date-time
        subscribers_notified:
          type: integer
          description: Number of subscribers notified
        error_message:
          type: string
          description: Error message if status is failed

    EventSubscription:
      type: object
      properties:
        subscription_id:
          type: string
          format: uuid
        service_name:
          type: string
          description: Subscribing service name
        event_pattern:
          type: string
          description: Event pattern to match
          example: "portfolio.*"
        webhook_url:
          type: string
          format: uri
          description: Webhook URL for event delivery
        active:
          type: boolean
          description: Whether subscription is active
        created_at:
          type: string
          format: date-time
        last_delivered_at:
          type: string
          format: date-time

    SubscriptionRequest:
      type: object
      required: [service_name, event_pattern, webhook_url]
      properties:
        service_name:
          type: string
          description: Name of subscribing service
        event_pattern:
          type: string
          description: Event pattern to subscribe to
          example: "portfolio.*"
        webhook_url:
          type: string
          format: uri
          description: Webhook URL for event delivery

    EventHistoryItem:
      type: object
      properties:
        event_id:
          type: string
          format: uuid
        event_type:
          type: string
        source_service:
          type: string
        timestamp:
          type: string
          format: date-time
        data_size:
          type: integer
          description: Size of event data in bytes
        subscribers_count:
          type: integer
          description: Number of subscribers that received the event
        processing_time_ms:
          type: number
          description: Event processing time in milliseconds

    EventBusHealth:
      type: object
      properties:
        status:
          type: string
          enum: [healthy, degraded, unhealthy]
        redis_connection:
          type: string
          enum: [connected, disconnected]
        active_subscriptions:
          type: integer
        events_processed_last_hour:
          type: integer
        average_processing_time_ms:
          type: number
        queue_size:
          type: integer
          description: Current event queue size
        last_event_processed_at:
          type: string
          format: date-time
```

---

## 📊 **5. MONITORING-SERVICE API**

### 5.1 **Monitoring-Service OpenAPI-Spezifikation**
```yaml
# services/monitoring-service/openapi.yaml
openapi: 3.1.0
info:
  title: Monitoring Service API
  description: System monitoring and analytics service
  version: 1.0.0

servers:
  - url: http://127.0.0.1:8004/api/v1
    description: Local development server

security:
  - ApiKeyAuth: []

paths:
  # System Health
  /health:
    get:
      summary: Overall system health
      description: Returns comprehensive system health status
      tags: [Health]
      responses:
        200:
          description: System health status
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/SystemHealth'

  /health/services:
    get:
      summary: Service health status
      description: Returns health status for all services
      tags: [Health]
      responses:
        200:
          description: Service health statuses
          content:
            application/json:
              schema:
                type: object
                properties:
                  services:
                    type: array
                    items:
                      $ref: '#/components/schemas/ServiceHealth'

  # Performance Metrics
  /metrics:
    get:
      summary: Get system metrics
      description: Returns current system performance metrics
      tags: [Metrics]
      parameters:
        - name: timeframe
          in: query
          description: Metrics timeframe
          schema:
            type: string
            enum: [1h, 6h, 24h, 7d, 30d]
            default: 1h
        - name: metric_types
          in: query
          description: Comma-separated list of metric types
          schema:
            type: string
            example: "cpu,memory,api_calls"
      responses:
        200:
          description: System metrics
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/SystemMetrics'

  /metrics/business:
    get:
      summary: Get business metrics
      description: Returns business-specific metrics
      tags: [Metrics]
      parameters:
        - name: timeframe
          in: query
          schema:
            type: string
            enum: [1h, 6h, 24h, 7d, 30d]
            default: 24h
      responses:
        200:
          description: Business metrics
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/BusinessMetrics'

  # Alerts
  /alerts:
    get:
      summary: Get active alerts
      description: Returns current active alerts
      tags: [Alerts]
      parameters:
        - name: severity
          in: query
          schema:
            type: string
            enum: [critical, warning, info]
        - name: resolved
          in: query
          description: Include resolved alerts
          schema:
            type: boolean
            default: false
      responses:
        200:
          description: Active alerts
          content:
            application/json:
              schema:
                type: object
                properties:
                  alerts:
                    type: array
                    items:
                      $ref: '#/components/schemas/Alert'

  /alerts/{alert_id}/acknowledge:
    post:
      summary: Acknowledge alert
      description: Acknowledges an alert
      tags: [Alerts]
      parameters:
        - name: alert_id
          in: path
          required: true
          schema:
            type: string
            format: uuid
      responses:
        200:
          description: Alert acknowledged
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Alert'

components:
  schemas:
    SystemHealth:
      type: object
      properties:
        overall_status:
          type: string
          enum: [healthy, degraded, unhealthy]
        health_score:
          type: integer
          minimum: 0
          maximum: 100
          description: Overall health score
        last_updated:
          type: string
          format: date-time
        uptime_seconds:
          type: integer
          description: System uptime in seconds
        components:
          type: object
          properties:
            database:
              $ref: '#/components/schemas/ComponentHealth'
            redis:
              $ref: '#/components/schemas/ComponentHealth'
            event_bus:
              $ref: '#/components/schemas/ComponentHealth'
            external_apis:
              $ref: '#/components/schemas/ComponentHealth'

    ComponentHealth:
      type: object
      properties:
        status:
          type: string
          enum: [healthy, degraded, unhealthy]
        response_time_ms:
          type: number
          description: Component response time
        last_check:
          type: string
          format: date-time
        error_message:
          type: string
          description: Error message if unhealthy

    ServiceHealth:
      type: object
      properties:
        service_name:
          type: string
        status:
          type: string
          enum: [running, stopped, error]
        health_status:
          type: string
          enum: [healthy, degraded, unhealthy]
        port:
          type: integer
        memory_usage_mb:
          type: number
        cpu_usage_percent:
          type: number
        last_restart:
          type: string
          format: date-time
        response_time_ms:
          type: number

    SystemMetrics:
      type: object
      properties:
        timestamp:
          type: string
          format: date-time
        cpu:
          type: object
          properties:
            usage_percent:
              type: number
            load_average:
              type: array
              items:
                type: number
        memory:
          type: object
          properties:
            usage_percent:
              type: number
            available_mb:
              type: number
            used_mb:
              type: number
        disk:
          type: object
          properties:
            usage_percent:
              type: number
            available_gb:
              type: number
        network:
          type: object
          properties:
            bytes_sent:
              type: integer
            bytes_received:
              type: integer
        api_metrics:
          type: object
          properties:
            requests_per_minute:
              type: number
            average_response_time_ms:
              type: number
            error_rate_percent:
              type: number

    BusinessMetrics:
      type: object
      properties:
        portfolio:
          type: object
          properties:
            total_value:
              type: number
            daily_pnl:
              type: number
            positions_count:
              type: integer
        trading:
          type: object
          properties:
            orders_today:
              type: integer
            successful_orders:
              type: integer
            trading_volume:
              type: number
        api_usage:
          type: object
          properties:
            bitpanda_calls:
              type: integer
            alpha_vantage_calls:
              type: integer
            success_rate_percent:
              type: number

    Alert:
      type: object
      properties:
        alert_id:
          type: string
          format: uuid
        severity:
          type: string
          enum: [critical, warning, info]
        title:
          type: string
          description: Alert title
        message:
          type: string
          description: Alert message
        source:
          type: string
          description: Alert source component
        created_at:
          type: string
          format: date-time
        acknowledged_at:
          type: string
          format: date-time
        resolved_at:
          type: string
          format: date-time
        metadata:
          type: object
          description: Additional alert metadata
```

---

## ✅ **6. IMPLEMENTIERUNGS-CHECKLIST**

### **Phase 1: OpenAPI-Schema-Definitionen (2-3 Tage)**
- [ ] Common-Components und Shared-Schemas erstellen
- [ ] OpenAPI-Validatoren für alle Services implementieren
- [ ] Swagger-UI-Integration für lokale Dokumentation
- [ ] Schema-Validation-Middleware für Flask-Services

### **Phase 2: Service-API-Implementation (3-4 Tage)**
- [ ] Intelligent-Core-Service API-Endpoints implementieren
- [ ] Broker-Gateway-Service Trading-APIs entwickeln
- [ ] Event-Bus-Service Event-Management-APIs
- [ ] Response-Schema-Compliance sicherstellen

### **Phase 3: Monitoring & Documentation (1-2 Tage)**
- [ ] Monitoring-Service API-Endpoints implementieren
- [ ] API-Documentation-Generation automatisieren
- [ ] Frontend-Service API-Proxy-Integration
- [ ] OpenAPI-Schema-Tests entwickeln

### **Phase 4: Integration & Testing (2-3 Tage)**
- [ ] Service-zu-Service-API-Calls implementieren
- [ ] End-to-End-API-Testing entwickeln
- [ ] API-Performance-Monitoring integrieren
- [ ] Client-Code-Generation für Frontend

**Gesamtaufwand**: 8-12 Tage
**Abhängigkeiten**: Alle 5 native Services, Flask-Framework

Diese Spezifikation bietet **vollständige OpenAPI 3.1-konforme APIs** für alle 5 Services mit konsistenten Schemas und Event-driven Architecture-Integration.