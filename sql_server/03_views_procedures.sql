-- ============================================================================
-- SQL Server Views & Procedures: EnterpriseSalesERP
-- ============================================================================

USE EnterpriseSalesERP;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- View 1: Customer Order Summary
CREATE OR ALTER VIEW sales.vw_CustomerOrderSummary AS
SELECT 
    c.CustomerID,
    c.ContactName,
    c.CompanyName,
    c.CustomerType,
    COUNT(o.OrderID) AS TotalOrdersPlaced,
    ISNULL(SUM(o.TotalAmount), 0.00) AS LifetimeOrderValue,
    MAX(o.OrderDate) AS MostRecentOrderDate,
    AVG(o.TotalAmount) AS AverageOrderValue
FROM core.Customers c
LEFT JOIN sales.Orders o ON c.CustomerID = o.CustomerID
GROUP BY 
    c.CustomerID,
    c.ContactName,
    c.CompanyName,
    c.CustomerType;
GO

-- View 2: Inventory Stock Reorder Alert
CREATE OR ALTER VIEW inventory.vw_LowStockProducts AS
SELECT 
    p.ProductID,
    p.SKU,
    p.ProductName,
    w.WarehouseCode,
    w.WarehouseName,
    inv.QuantityOnHand,
    inv.QuantityReserved,
    inv.ReorderPoint,
    (inv.QuantityOnHand - inv.QuantityReserved) AS AvailableStock,
    CASE 
        WHEN (inv.QuantityOnHand - inv.QuantityReserved) <= inv.ReorderPoint THEN 'REORDER_NOW'
        WHEN (inv.QuantityOnHand - inv.QuantityReserved) <= (inv.ReorderPoint + inv.SafetyStock) THEN 'LOW_WARNING'
        ELSE 'SUFFICIENT'
    END AS StockStatus
FROM inventory.ProductInventory inv
JOIN inventory.Products p ON inv.ProductID = p.ProductID
JOIN inventory.Warehouses w ON inv.WarehouseID = w.WarehouseID
WHERE (inv.QuantityOnHand - inv.QuantityReserved) <= (inv.ReorderPoint + inv.SafetyStock);
GO

-- Stored Procedure 1: Update Stock Level
CREATE OR ALTER PROCEDURE inventory.usp_UpdateStockLevel
    @ProductID INT,
    @WarehouseID INT,
    @QuantityChange INT,
    @TransactionType VARCHAR(30),
    @ReferenceDoc VARCHAR(100),
    @Notes NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Update inventory on hand
        UPDATE inventory.ProductInventory
        SET QuantityOnHand = QuantityOnHand + @QuantityChange,
            LastRestockedAt = CASE WHEN @QuantityChange > 0 THEN SYSUTCDATETIME() ELSE LastRestockedAt END
        WHERE ProductID = @ProductID AND WarehouseID = @WarehouseID;

        -- Record transaction log
        INSERT INTO inventory.InventoryTransactions (
            ProductID, WarehouseID, TransactionType, QuantityDelta, ReferenceDocument, Notes, TransactionDate
        ) VALUES (
            @ProductID, @WarehouseID, @TransactionType, @QuantityChange, @ReferenceDoc, @Notes, SYSUTCDATETIME()
        );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO
