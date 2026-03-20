namespace Shared.Vouchers
{
    public class BulkCreateVoucherRequest
    {
        public int VoucherTemplateId { get; set; }
        public List<string> AccountIds { get; set; } = new();
        public DateTimeOffset? Expiry { get; set; }
    }
}
