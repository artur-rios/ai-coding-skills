# Worked example — C# / xUnit

A small `CartService` and a suite that demonstrates the Given-When-Then naming
rule and edge-case coverage. Port the same structure to your project's framework
(NUnit/MSTest/Jest/pytest/JUnit) — the naming and the scenario coverage are what
matter, not the specific library.

## Code under test

```csharp
public interface IPaymentGateway
{
    Receipt Charge(int total);
}

public class Receipt;

public class PaymentDeclinedException : Exception;

public class Cart
{
    private readonly Dictionary<string, int> _items = new();
    public IReadOnlyDictionary<string, int> Items => _items;

    public void Add(string sku, int quantity)
    {
        if (sku is null) throw new ArgumentNullException(nameof(sku));
        if (quantity <= 0) throw new ArgumentOutOfRangeException(nameof(quantity));
        _items[sku] = _items.GetValueOrDefault(sku) + quantity;
    }
}

public class CartService
{
    private readonly Cart _cart;
    private readonly IPaymentGateway _gateway;

    public CartService(Cart cart, IPaymentGateway gateway)
    {
        _cart = cart;
        _gateway = gateway;
    }

    public void AddItem(string sku, int quantity) => _cart.Add(sku, quantity);

    public Receipt Checkout()
    {
        if (_cart.Items.Count == 0)
            throw new InvalidOperationException("Cart is empty.");

        var total = _cart.Items.Values.Sum();
        return _gateway.Charge(total);   // returns a Receipt
    }
}
```

## Test suite

Note how the scenario list from `edge-cases.md` maps to tests: happy path,
boundaries (non-positive quantity), empty (empty cart), interaction (gateway
called with the right total), and error propagation (gateway throws).

```csharp
using Moq;
using Xunit;

// The category lets CI run unit and functional tests as separate jobs
// (dotnet test --filter "Category=Unit"). Use the project's own marker.
[Trait("Category", "Unit")]
public class CartServiceTests
{
    private static CartService MakeSut(out Mock<IPaymentGateway> gateway, Cart? cart = null)
    {
        gateway = new Mock<IPaymentGateway>();
        return new CartService(cart ?? new Cart(), gateway.Object);
    }

    // ---- AddItem ----------------------------------------------------------

    [Fact]
    public void GivenValidSkuAndQuantity_WhenAddItem_ThenItemIsInCart()
    {
        var cart = new Cart();
        var sut = MakeSut(out _, cart);

        sut.AddItem("sku-1", 2);

        Assert.Equal(2, cart.Items["sku-1"]);
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    [InlineData(int.MinValue)]
    public void GivenNonPositiveQuantity_WhenAddItem_ThenThrowsArgumentOutOfRange(int qty)
    {
        var sut = MakeSut(out _);

        var act = () => sut.AddItem("sku-1", qty);

        Assert.Throws<ArgumentOutOfRangeException>(act);
    }

    [Fact]
    public void GivenNullSku_WhenAddItem_ThenThrowsArgumentNull()
    {
        var sut = MakeSut(out _);

        var act = () => sut.AddItem(null!, 1);

        Assert.Throws<ArgumentNullException>(act);
    }

    [Fact]
    public void GivenExistingSku_WhenAddItemAgain_ThenQuantityAccumulates()
    {
        var cart = new Cart();
        var sut = MakeSut(out _, cart);

        sut.AddItem("sku-1", 2);
        sut.AddItem("sku-1", 3);

        Assert.Equal(5, cart.Items["sku-1"]);
    }

    // ---- Checkout ---------------------------------------------------------

    [Fact]
    public void GivenEmptyCart_WhenCheckout_ThenThrowsInvalidOperation()
    {
        var sut = MakeSut(out _);

        var act = () => sut.Checkout();

        Assert.Throws<InvalidOperationException>(act);
    }

    [Fact]
    public void GivenCartWithItems_WhenCheckout_ThenChargesGatewayWithTotal()
    {
        var cart = new Cart();
        var sut = MakeSut(out var gateway, cart);
        gateway.Setup(g => g.Charge(It.IsAny<int>())).Returns(new Receipt());
        sut.AddItem("sku-1", 2);
        sut.AddItem("sku-2", 3);

        sut.Checkout();

        gateway.Verify(g => g.Charge(5), Times.Once);   // interaction + right total
    }

    [Fact]
    public void GivenGatewayThatThrows_WhenCheckout_ThenExceptionPropagates()
    {
        var cart = new Cart();
        var sut = MakeSut(out var gateway, cart);
        gateway.Setup(g => g.Charge(It.IsAny<int>())).Throws<PaymentDeclinedException>();
        sut.AddItem("sku-1", 1);

        var act = () => sut.Checkout();

        Assert.Throws<PaymentDeclinedException>(act);
    }
}
```

## Why these tests

| Test | Category (from edge-cases.md) |
|---|---|
| `GivenValidSkuAndQuantity_…_ThenItemIsInCart` | Happy path |
| `GivenNonPositiveQuantity_…_ThenThrowsArgumentOutOfRange` | Boundaries / invalid input |
| `GivenNullSku_…_ThenThrowsArgumentNull` | Null input |
| `GivenExistingSku_WhenAddItemAgain_…Accumulates` | State / mutation |
| `GivenEmptyCart_…_ThenThrowsInvalidOperation` | Empty |
| `GivenCartWithItems_…_ThenChargesGatewayWithTotal` | Interaction |
| `GivenGatewayThatThrows_…_ThenExceptionPropagates` | Error propagation |
