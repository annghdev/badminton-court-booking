using Domain.Repositories;

namespace Application.Features.Facilities.Queries
{
    public record GetFacilityQuery(int id) : IRequest<Facility>
    {
    }

    public class GetFacilityQueryHandler : IRequestHandler<GetFacilityQuery, Facility>
    {
        private readonly IRepository<Facility> _repository;
        public GetFacilityQueryHandler(IRepository<Facility> repository)
        {
            _repository = repository;
        }
        public async Task<Facility> Handle(GetFacilityQuery request, CancellationToken cancellationToken)
        {
            return await _repository.FindAsync(request.id, cancellationToken);
        }
    }
}
