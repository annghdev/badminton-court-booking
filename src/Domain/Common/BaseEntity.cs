using System.ComponentModel.DataAnnotations;

namespace Domain.Common
{
    public abstract class BaseEntity<T>
    {
        [Key]
        public T Id { get; set; }
    }
}
